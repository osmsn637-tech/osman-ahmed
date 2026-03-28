import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import ffmpegPath from 'ffmpeg-static';
import * as googleTTS from 'google-tts-api';
import { chromium } from 'playwright';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..', '..');
const buildOutputRoot = path.join(repoRoot, 'docs', 'training', 'adjust-item', 'build');
const tempRoot = path.join(repoRoot, 'docs', 'training', 'adjust-item', 'temp');
const outputRoot = path.join(repoRoot, 'docs', 'training', 'adjust-item', 'output');
const flutterCommand = await resolveFlutterCommand();

const scenarios = [
  {
    locale: 'en',
    audioFile: 'adjust-item-training-en.mp3',
    videoFile: 'adjust-item-training-en.mp4',
    rawVideoFile: 'adjust-item-training-en.raw.webm',
    waitMs: 26000,
    narration:
      'Review the item details and choose the location you want to adjust. Enter the new quantity for that location, then tap Confirm. When the success message appears, the adjustment is complete.',
  },
  {
    locale: 'ar',
    audioFile: 'adjust-item-training-ar.mp3',
    videoFile: 'adjust-item-training-ar.mp4',
    rawVideoFile: 'adjust-item-training-ar.raw.webm',
    waitMs: 26000,
    narration:
      'راجع بيانات الصنف واختر الموقع الذي تريد تعديله. أدخل الكمية الجديدة لهذا الموقع ثم اضغط على تأكيد. عند ظهور رسالة النجاح تكون عملية التعديل قد اكتملت.',
  },
];

await fs.mkdir(buildOutputRoot, { recursive: true });
await fs.mkdir(tempRoot, { recursive: true });
await fs.mkdir(outputRoot, { recursive: true });

for (const scenario of scenarios) {
  console.log(`\n=== Building ${scenario.locale} training app ===`);
  await buildTrainingApp(scenario.locale);

  const localeBuildDir = path.join(buildOutputRoot, scenario.locale);
  const localeTempDir = path.join(tempRoot, scenario.locale);
  await fs.rm(localeBuildDir, { recursive: true, force: true });
  await fs.cp(path.join(repoRoot, 'build', 'web'), localeBuildDir, {
    recursive: true,
  });
  await fs.rm(localeTempDir, { recursive: true, force: true });
  await fs.mkdir(localeTempDir, { recursive: true });

  const rawVideoPath = path.join(localeTempDir, scenario.rawVideoFile);
  const audioPath = path.join(outputRoot, scenario.audioFile);
  const finalVideoPath = path.join(outputRoot, scenario.videoFile);

  await fs.rm(rawVideoPath, { force: true });
  await fs.rm(audioPath, { force: true });
  await fs.rm(finalVideoPath, { force: true });

  console.log(`=== Serving ${scenario.locale} build ===`);
  const port = scenario.locale === 'ar' ? 4841 : 4840;
  const server = await startStaticServer(localeBuildDir, port);

  try {
    console.log(`=== Capturing ${scenario.locale} walkthrough ===`);
    await captureWalkthrough({
      url: `http://127.0.0.1:${port}`,
      locale: scenario.locale,
      waitMs: scenario.waitMs,
      rawVideoPath,
    });
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }

  console.log(`=== Generating ${scenario.locale} narration ===`);
  await synthesizeNarration({
    text: scenario.narration,
    locale: scenario.locale,
    outputPath: audioPath,
  });

  console.log(`=== Exporting ${scenario.locale} MP4 ===`);
  await composeVideo({
    rawVideoPath,
    audioPath,
    outputPath: finalVideoPath,
  });
}

console.log('\nTraining videos exported to:');
console.log(outputRoot);

async function buildTrainingApp(locale) {
  await run(flutterCommand, [
    'build',
    'web',
    '--release',
    '-t',
    'lib/training/main_adjust_training.dart',
    `--dart-define=TRAINING_LOCALE=${locale}`,
  ]);
}

async function captureWalkthrough({ url, locale, waitMs, rawVideoPath }) {
  const recordDir = path.dirname(rawVideoPath);
  await fs.mkdir(recordDir, { recursive: true });
  const existingFiles = await fs.readdir(recordDir);
  for (const file of existingFiles) {
    if (file.endsWith('.webm')) {
      await fs.rm(path.join(recordDir, file), { force: true });
    }
  }

  const browser = await launchBrowser();

  try {
    const context = await browser.newContext({
      locale: locale === 'ar' ? 'ar-SA' : 'en-US',
      viewport: { width: 430, height: 932 },
      deviceScaleFactor: 1,
      recordVideo: {
        dir: recordDir,
        size: { width: 430, height: 932 },
      },
    });
    const page = await context.newPage();
    await page.goto(url, { waitUntil: 'load' });
    await page.waitForTimeout(waitMs);
    await context.close();
  } finally {
    await browser.close();
  }

  const files = await fs.readdir(recordDir);
  const recorded = files
      .filter((file) => file.endsWith('.webm'))
      .map((file) => path.join(recordDir, file))
      .sort((left, right) => right.localeCompare(left))[0];

  if (!recorded) {
    throw new Error(`No recorded video found in ${recordDir}`);
  }

  await fs.rename(recorded, rawVideoPath);
}

async function launchBrowser() {
  const attempts = [
    { channel: 'msedge' },
    { channel: 'chrome' },
    {},
  ];

  let lastError;
  for (const options of attempts) {
    try {
      return await chromium.launch({
        ...options,
        headless: true,
      });
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
}

async function synthesizeNarration({ text, locale, outputPath }) {
  const hosts = [
    'https://translate.google.com',
    'https://translate.google.com.cn',
  ];
  let lastError;

  for (const host of hosts) {
    try {
      const pieces = await googleTTS.getAllAudioBase64(text, {
        lang: locale === 'ar' ? 'ar' : 'en',
        slow: false,
        timeout: 20000,
        host,
        splitPunct: locale === 'ar' ? '،.؟!' : ',.?!',
      });
      const audio = Buffer.concat(
        pieces.map((piece) => Buffer.from(piece.base64, 'base64')),
      );
      await fs.writeFile(outputPath, audio);
      return;
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
}

async function composeVideo({ rawVideoPath, audioPath, outputPath }) {
  if (!ffmpegPath) {
    throw new Error('ffmpeg-static did not provide a binary path');
  }

  await run(ffmpegPath, [
    '-y',
    '-i',
    rawVideoPath,
    '-i',
    audioPath,
    '-c:v',
    'libx264',
    '-preset',
    'veryfast',
    '-pix_fmt',
    'yuv420p',
    '-movflags',
    '+faststart',
    '-c:a',
    'aac',
    outputPath,
  ]);
}

async function run(command, args, options = {}) {
  await new Promise((resolve, reject) => {
    const useShell =
      options.shell ??
      (process.platform === 'win32' && command.toLowerCase().endsWith('.bat'));
    const child = spawn(command, args, {
      cwd: repoRoot,
      stdio: 'inherit',
      shell: useShell,
      ...options,
    });

    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`${command} ${args.join(' ')} exited with code ${code}`));
    });
  });
}

async function resolveFlutterCommand() {
  if (process.env.FLUTTER_BIN) {
    return process.env.FLUTTER_BIN;
  }

  const candidatePaths = [
    path.join(
      process.env.USERPROFILE ?? '',
      'Downloads',
      'flutter_windows_3.24.0-stable',
      'flutter',
      'bin',
      'flutter.bat',
    ),
    path.join(
      process.env.USERPROFILE ?? '',
      'flutter',
      'bin',
      'flutter.bat',
    ),
    'flutter',
  ];

  for (const candidate of candidatePaths) {
    if (candidate === 'flutter') {
      return candidate;
    }
    try {
      await fs.access(candidate);
      return candidate;
    } catch (_) {
      // Try the next location.
    }
  }

  return 'flutter';
}

async function startStaticServer(rootDir, port) {
  await fs.mkdir(rootDir, { recursive: true });

  const server = http.createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
      const relativePath = decodeURIComponent(requestUrl.pathname);
      const candidatePath = relativePath === '/'
          ? path.join(rootDir, 'index.html')
          : path.join(rootDir, relativePath.replace(/^\/+/, ''));

      let filePath = candidatePath;
      let stats;

      try {
        stats = await fs.stat(filePath);
      } catch (_) {
        filePath = path.join(rootDir, 'index.html');
        stats = await fs.stat(filePath);
      }

      if (stats.isDirectory()) {
        filePath = path.join(filePath, 'index.html');
      }

      const content = await fs.readFile(filePath);
      response.writeHead(200, {
        'Content-Type': contentTypeFor(filePath),
        'Cache-Control': 'no-store',
      });
      response.end(content);
    } catch (error) {
      response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end(String(error));
    }
  });

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', resolve);
  });

  return server;
}

function contentTypeFor(filePath) {
  const extension = path.extname(filePath).toLowerCase();
  switch (extension) {
    case '.html':
      return 'text/html; charset=utf-8';
    case '.js':
      return 'application/javascript; charset=utf-8';
    case '.css':
      return 'text/css; charset=utf-8';
    case '.json':
      return 'application/json; charset=utf-8';
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.svg':
      return 'image/svg+xml';
    case '.wasm':
      return 'application/wasm';
    case '.ico':
      return 'image/x-icon';
    case '.ttf':
      return 'font/ttf';
    case '.woff':
      return 'font/woff';
    case '.woff2':
      return 'font/woff2';
    default:
      return 'application/octet-stream';
  }
}

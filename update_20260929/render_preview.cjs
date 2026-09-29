const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const { pathToFileURL } = require('url');
const path = require('path');
(async () => {
 const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
 const page = await browser.newPage({viewport:{width:1920,height:1080}, deviceScaleFactor:1});
 await page.goto(pathToFileURL(path.resolve('preview.html')).href);
 await page.locator('.hud').screenshot({path:'preview_hud_ready.png'});
 await page.locator('button').click();
 await page.locator('.hud').screenshot({path:'preview_hud_cooldown.png'});
 for(const width of [1920,1280,800]) {
  await page.setViewportSize({width,height:1080});
  const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
  console.log('Viewport',width,'horizontal overflow:',overflow);
 }
 await browser.close();
})();


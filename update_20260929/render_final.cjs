const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const { pathToFileURL } = require('url');
const path = require('path');
(async () => {
 const browser = await chromium.launch({ executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe', headless:true });
 const page=await browser.newPage({viewport:{width:1920,height:1080},deviceScaleFactor:1});
 await page.goto(pathToFileURL(path.resolve('preview.html')).href);
 await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete));
 const missing=await page.evaluate(()=>Array.from(document.images).filter(i=>i.naturalWidth===0).map(i=>i.src));
 if(missing.length)throw new Error('Missing images: '+JSON.stringify(missing));
 const clipped=await page.evaluate(()=>{
  const bounds=document.querySelector('.hud').getBoundingClientRect();
  return Array.from(document.querySelectorAll('.hint')).some(n=>n.getBoundingClientRect().bottom>bounds.bottom-1);
 });
 if(clipped)throw new Error('HUD hints are clipped');
 await page.screenshot({path:'preview_all_assets.png',fullPage:true});
 console.log('All preview images loaded; HUD hints fully visible.');
 await browser.close();
})();

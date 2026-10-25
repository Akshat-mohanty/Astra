document.documentElement.dataset.astraExtension = chrome.runtime.id;
chrome.runtime.sendMessage({op: "ping"}).then(result => {
  document.documentElement.dataset.astraWorker = JSON.stringify(result);
}).catch(error => {
  document.documentElement.dataset.astraWorkerError = String(error);
});

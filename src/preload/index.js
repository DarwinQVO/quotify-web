const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  scrapeMetadata: (url) => ipcRenderer.invoke('scrape-metadata', url),
  transcribeAudio: (data) => ipcRenderer.invoke('transcribe-audio', data),
  generateDeepLink: (data) => ipcRenderer.invoke('generate-deep-link', data),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  saveApiKey: (apiKey) => ipcRenderer.invoke('save-api-key', apiKey),
  loadApiKey: () => ipcRenderer.invoke('load-api-key'),
  saveGeminiConfig: (config) => ipcRenderer.invoke('save-gemini-config', config),
  loadGeminiConfig: () => ipcRenderer.invoke('load-gemini-config'),
  saveAppData: (data) => ipcRenderer.invoke('save-app-data', data),
  loadAppData: () => ipcRenderer.invoke('load-app-data'),
  reprocessWithGemini: (data) => ipcRenderer.invoke('reprocess-with-gemini', data),
});
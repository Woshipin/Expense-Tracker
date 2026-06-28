import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.sunset.tracker',
  appName: 'Sunset Tracker',
  webDir: 'out',
  // 【修正】：将 allowMixedContent 放入 android 属性块中，符合官方 TypeScript 类型定义
  android: {
    allowMixedContent: true
  }
};

export default config;
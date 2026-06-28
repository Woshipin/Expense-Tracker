import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // 1. 启用静态导出，打包出 "out" 文件夹
  output: 'export',       

  // 2. 极其重要：确保打包后的页面路由在手机原生 WebView 上能够被正确定位，防止 404
  trailingSlash: false,    

  // 3. 必须：禁用默认的图片优化，因为静态导出不支持 Next.js 的动态图片服务
  images: {
    unoptimized: true,    
  },
};

export default nextConfig;
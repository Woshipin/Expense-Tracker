import axios from "axios";

/**
 * 智能动态获取 API 基础路径
 * 通过端口号（3000）100% 精准区分：电脑本地浏览器 与 手机原生 App 运行环境！
 */
const getBaseURL = (): string => {
  const localUrl = process.env.NEXT_PUBLIC_API_URL_LOCAL || "http://127.0.0.1:8000/api";
  const lanUrl = process.env.NEXT_PUBLIC_API_URL_LAN || "http://10.200.242.154:8000/api";

  if (typeof window !== "undefined") {
    const hostname = window.location.hostname;
    const port = window.location.port;

    // 只有在电脑浏览器上（域名是 localhost 或 127.0.0.1，且端口是 3000）才使用本地地址
    if ((hostname === "localhost" || hostname === "127.0.0.1") && port === "3000") {
      return localUrl;
    }

    // 手机 App（运行在 https://localhost 且没有 3000 端口）或者手机局域网测试，一律使用局域网 IP
    return lanUrl;
  }

  return localUrl;
};

const api = axios.create({
  baseURL: getBaseURL(),
  
  // 允许跨域携带 Cookie (网站端本地开发继续起效)
  withCredentials: true, 
  
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
  },
});

// 请求拦截器：如果本地存有 Bearer Token (仅在手机端 App 登录时会写入)，
// 则自动在每个网络请求的 Request Header 中携带，从而绕过手机端的 Cookie 限制。
api.interceptors.request.use(
  (config) => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("auth_token");
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default api;
import axios from "axios";

// 候选 API 轮询队列 (手机 App 使用)
const CANDIDATE_URLS = [
  "http://localhost:8000/api",
  "http://192.168.0.152.nip.io:8000/api",
  "http://192.168.0.132.nip.io:8000/api",
  "http://10.200.242.154.nip.io:8000/api",
];

// 【高级自适应自检】：初始化时判定是否属于生产环境
const getInitialBaseURL = () => {
  if (typeof window !== "undefined") {
    const hostname = window.location.hostname;

    // 判定是否为线上部署环境（既不是 localhost，也不包含局域网 IP段）
    const isProduction =
      hostname !== "localhost" &&
      hostname !== "127.0.0.1" &&
      !hostname.startsWith("192.168.") &&
      !hostname.startsWith("10.200.");

    if (isProduction) {
      // 线上环境必须强制使用 https 的 Railway 后端 API，避免混合内容(Mixed Content)警告
      return "https://expense-tracker-production-b2b0.up.railway.app/api";
    }

    // 本地开发调试：自适应同步宿主域名
    return `http://${hostname}:8000/api`;
  }
  return "http://localhost:8000/api";
};

let activeBaseURL = getInitialBaseURL();
let isDetected = false;

const api = axios.create({
  baseURL: activeBaseURL,
  withCredentials: true, 
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
  },
});

/**
 * 智能动态获取 API 基础路径
 */
export const findWorkingApiURL = async (): Promise<string> => {
  if (typeof window === "undefined") return activeBaseURL;

  const hostname = window.location.hostname;

  // 1. 优先判定：如果是线上生产环境，立刻锁定 Railway 接口，跳过所有局域网雷达探测
  const isProduction =
    hostname !== "localhost" &&
    hostname !== "127.0.0.1" &&
    !hostname.startsWith("192.168.") &&
    !hostname.startsWith("10.200.");

  if (isProduction) {
    activeBaseURL = "https://expense-tracker-production-b2b0.up.railway.app/api";
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  // 如果已经探测完成，则直接返回上次探测到的地址
  if (isDetected) {
    return activeBaseURL;
  }

  const port = window.location.port;

  // 2. 电脑端开发环境直接绑定 localhost，锁定缓存
  if ((hostname === "localhost" || hostname === "127.0.0.1") && port === "3000") {
    activeBaseURL = `http://localhost:8000/api`;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  // 3. 电脑端基于局域网 IP / nip.io 访问测试，动态对齐并锁定
  if (hostname !== "localhost" && hostname !== "127.0.0.1" && port === "3000") {
    activeBaseURL = `http://${hostname}:8000/api`;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  // 4. 原生手机 App (Capacitor/React Native) 探测
  const tempInstance = axios.create({ timeout: 1500 }); 

  for (const url of CANDIDATE_URLS) {
    try {
      await tempInstance.get(`${url}/me`);
      activeBaseURL = url;
      api.defaults.baseURL = activeBaseURL;
      isDetected = true;
      console.log(`[雷达检测] 成功通过连接锁定 API: ${url}`);
      return url;
    } catch (error: any) {
      if (error.response && (error.response.status === 401 || error.response.status === 403)) {
        activeBaseURL = url;
        api.defaults.baseURL = activeBaseURL;
        isDetected = true;
        console.log(`[雷达检测] 成功通过安全校验锁定 API: ${url}`);
        return url;
      }
      continue;
    }
  }

  console.warn(`[雷达检测] 所有局域网接口均不可达，将使用默认备用: ${activeBaseURL}`);
  return activeBaseURL;
};

// 请求拦截器
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
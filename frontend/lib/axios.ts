import axios from "axios";

// =========================================================================
// 【手动一键切换区】
//  "local"      => 强制锁定本地 API (http://localhost:8000/api)
//  "production" => 强制锁定生产环境 API (https://expense-tracker-production-b2b0.up.railway.app/api)
//  "auto"       => 开启自适应检测（根据当前域名或手机雷达自检）
// =========================================================================
const CURRENT_API_MODE: "local" | "production" | "auto" = "local"; // <--- 在这里修改即可！

// -------------------------------------------------------------------------
const PRODUCTION_API_URL = "https://expense-tracker-production-b2b0.up.railway.app/api";
const LOCAL_API_URL = "http://localhost:8000/api";

const CANDIDATE_URLS = [
  LOCAL_API_URL,
  "http://192.168.0.152.nip.io:8000/api",
  "http://192.168.0.132.nip.io:8000/api",
  "http://10.200.242.154.nip.io:8000/api",
];

const checkIsProductionHost = (hostname: string): boolean => {
  return (
    hostname !== "localhost" &&
    hostname !== "127.0.0.1" &&
    !hostname.startsWith("192.168.") &&
    !hostname.startsWith("10.200.") &&
    !hostname.includes("nip.io")
  );
};

const getInitialBaseURL = () => {
  if (typeof window !== "undefined") {
    // 1. 【改进】：如果手动设置了强制模式，优先服从
    if (CURRENT_API_MODE === "local") {
      return LOCAL_API_URL;
    }
    if (CURRENT_API_MODE === "production") {
      return PRODUCTION_API_URL;
    }

    // 2. 备用手动 localStorage 覆盖
    const manualOverride = localStorage.getItem("NEXT_PUBLIC_API_URL");
    if (manualOverride) {
      return manualOverride;
    }

    // 3. "auto" 模式下的自动判断逻辑
    const hostname = window.location.hostname;
    if (hostname === "localhost" || hostname === "127.0.0.1") {
      return LOCAL_API_URL;
    }
    if (checkIsProductionHost(hostname)) {
      return PRODUCTION_API_URL;
    }
    return `http://${hostname}:8000/api`;
  }
  return LOCAL_API_URL;
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

export const findWorkingApiURL = async (): Promise<string> => {
  if (typeof window === "undefined") return activeBaseURL;

  // 1. 【改进】：如果手动设置了强制模式，优先服从并跳过后续探测
  if (CURRENT_API_MODE === "local") {
    activeBaseURL = LOCAL_API_URL;
    api.defaults.baseURL = activeBaseURL;
    return activeBaseURL;
  }
  if (CURRENT_API_MODE === "production") {
    activeBaseURL = PRODUCTION_API_URL;
    api.defaults.baseURL = activeBaseURL;
    return activeBaseURL;
  }

  const manualOverride = localStorage.getItem("NEXT_PUBLIC_API_URL");
  if (manualOverride) {
    activeBaseURL = manualOverride;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  const hostname = window.location.hostname;

  if (hostname === "localhost" || hostname === "127.0.0.1") {
    activeBaseURL = LOCAL_API_URL;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  if (checkIsProductionHost(hostname)) {
    activeBaseURL = PRODUCTION_API_URL;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  if (isDetected) {
    return activeBaseURL;
  }

  const port = window.location.port;

  if (hostname !== "localhost" && hostname !== "127.0.0.1" && port === "3000") {
    activeBaseURL = `http://${hostname}:8000/api`;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true;
    return activeBaseURL;
  }

  const tempInstance = axios.create({ timeout: 1500 }); 

  for (const url of CANDIDATE_URLS) {
    try {
      await tempInstance.get(`${url}/me`);
      activeBaseURL = url;
      api.defaults.baseURL = activeBaseURL;
      isDetected = true;
      return url;
    } catch (error: any) {
      if (error.response && (error.response.status === 401 || error.response.status === 403)) {
        activeBaseURL = url;
        api.defaults.baseURL = activeBaseURL;
        isDetected = true;
        return url;
      }
      continue;
    }
  }

  return activeBaseURL;
};

// 请求拦截器保持不变...
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
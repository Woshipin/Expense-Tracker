import axios from "axios";

// 候选 API 轮询队列
const CANDIDATE_URLS = [
  "http://127.0.0.1:8000/api",      // 1. 本地
  "http://192.168.0.152:8000/api",  // 2. 新山
  "http://192.168.0.132:8000/api",  // 3. Ah
  "http://10.200.242.154:8000/api",  // 4. 个人热点
];

// 默认安全主路由
let activeBaseURL = "http://127.0.0.1:8000/api";
let isDetected = false; // 【新增缓存标志】：一旦锁定 IP，永久不再重复扫网，耗时归零！

const api = axios.create({
  baseURL: activeBaseURL,
  withCredentials: true, 
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
  },
});

/**
 * 智能动态获取 API 基础路径（已集成永久锁定缓存）
 */
export const findWorkingApiURL = async (): Promise<string> => {
  if (typeof window === "undefined") return activeBaseURL;

  // 【核心优化】：如果已经探测成功过一次，直接返回缓存地址，绝对不再重复扫网！
  if (isDetected) {
    return activeBaseURL;
  }

  const hostname = window.location.hostname;
  const port = window.location.port;

  // 1. 电脑端开发环境（localhost:3000）直接绑定本地回环，锁定缓存并返回
  if ((hostname === "localhost" || hostname === "127.0.0.1") && port === "3000") {
    activeBaseURL = `http://${hostname}:8000/api`;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true; // 锁定状态
    return activeBaseURL;
  }

  // 2. 电脑端通过特定局域网 IP:3000 访问测试，直接对应匹配并锁定
  if (hostname !== "localhost" && hostname !== "127.0.0.1" && port === "3000") {
    activeBaseURL = `http://${hostname}:8000/api`;
    api.defaults.baseURL = activeBaseURL;
    isDetected = true; // 锁定状态
    return activeBaseURL;
  }

  // 3. 原生手机 App (Capacitor) 环境，依次轮询探测可通的局域网/本机节点
  const tempInstance = axios.create({ timeout: 1200 }); 

  for (const url of CANDIDATE_URLS) {
    try {
      await tempInstance.get(`${url}/me`);
      activeBaseURL = url;
      api.defaults.baseURL = activeBaseURL;
      isDetected = true; // 成功连接后锁定，下次不再探测
      console.log(`[雷达检测] 成功通过正常连接锁定 API: ${url}`);
      return url;
    } catch (error: any) {
      if (error.response) {
        activeBaseURL = url;
        api.defaults.baseURL = activeBaseURL;
        isDetected = true; // 只要能返回响应（包含 401），说明通畅，直接锁定
        console.log(`[雷达检测] 成功通过安全校验响应锁定 API: ${url}`);
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
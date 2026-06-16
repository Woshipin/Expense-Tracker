import axios from "axios";

const api = axios.create({
  // 使用环境变量，如果没有配置则默认指向 localhost:8000/api
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api",
  
  // 🚨极其重要：允许跨域携带 Cookie。这对应了你后端 CORS 配置的 supports_credentials = true
  withCredentials: true, 
  
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
  },
});

export default api;
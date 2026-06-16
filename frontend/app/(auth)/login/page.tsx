"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
// 【修改】引入 useSearchParams 用于捕获后端重定向回来的错误参数
import { useRouter, useSearchParams } from "next/navigation"; 
import {
  ArrowLeft,
  Eye,
  EyeOff,
  LogIn,
  Lock,
  Mail,
  Loader2,
  Globe,
} from "lucide-react";
import { Input, Toast } from "@/components/ui";
import api from "@/lib/axios";

interface LoadingOverlayProps {
  title?: string;
  description?: string;
  isFullScreen?: boolean;
}

const LoadingOverlay: React.FC<LoadingOverlayProps> = ({
  title,
  description,
  isFullScreen = false,
}) => {
  const loadingContent = (
    <div className="text-center bg-white px-16 py-8 md:px-20 md:py-10 rounded-3xl shadow-2xl border border-orange-200 w-full max-w-md md:max-w-lg mx-4">
      <div className="relative inline-block">
        <Loader2 className="h-16 w-16 animate-spin text-orange-500" />
        <div className="absolute inset-0 h-16 w-16 border-4 border-orange-200 rounded-full mx-auto animate-pulse"></div>
      </div>
      <h3 className="mt-6 text-xl font-semibold text-gray-800">
        {title || "Loading"}
      </h3>
      <p className="mt-2 text-gray-600">
        {description || "Please wait while we load the content..."}
      </p>
      <div className="mt-4 flex justify-center space-x-1">
        <div className="w-2 h-2 bg-orange-400 rounded-full animate-bounce"></div>
        <div
          className="w-2 h-2 bg-orange-400 rounded-full animate-bounce"
          style={{ animationDelay: "0.1s" }}
        ></div>
        <div
          className="w-2 h-2 bg-orange-400 rounded-full animate-bounce"
          style={{ animationDelay: "0.2s" }}
        ></div>
      </div>
    </div>
  );

  if (isFullScreen) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-orange-50/80 backdrop-blur-sm">
        {loadingContent}
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center min-h-[300px] py-10">
      {loadingContent}
    </div>
  );
};

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams(); // 【新增】初始化获取 URL 参数的钩子
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [toast, setToast] = useState<{message:string, type:'error'|'success'} | null>(null);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false,
  });
  const [errors, setErrors] = useState<any>({});

  // 【新增】监听并捕获后端 Socialite 回调传过来的错误代码
  useEffect(() => {
    const error = searchParams.get('error');
    if (error === 'social_auth_failed') {
      setToast({ message: "Social login failed or cancelled. (第三方登录取消或失败)", type: "error" });
    } else if (error === 'account_banned') {
      setToast({ message: "Your account has been banned. (您的账号已被封禁)", type: "error" });
    }
  }, [searchParams]);

  useEffect(() => {
    setFormData((prev) => ({
      ...prev,
      email: "",
      password: "",
    }));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrors({});

    try {
      const response = await api.post("/login", {
        email: formData.email,
        password: formData.password,
      });

      setToast({ message: "Login successful", type: "success" });
      
      // 等待 1.5 秒后跳转
      setTimeout(() => {
        router.push("/dashboard");
      }, 1500);

    } catch (error: any) {
      setIsLoading(false);
      
      if (error.response) {
        if (error.response.status === 422) {
          setErrors(error.response.data.errors || {});
        } else if (error.response.status === 401 || error.response.status === 403) {
          setToast({ message: error.response.data.error || "Login failed", type: "error" });
        } else {
          setToast({ message: "Server error. Please try again later.", type: "error" });
        }
      } else {
        setToast({ message: "Network error. Please check your connection.", type: "error" });
      }
    } 
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  // 【修改】真实对接后端的 Laravel Socialite 第三方授权路由
  const handleSocialLoginClick = (provider: string) => {
    setIsLoading(true); // 显示全屏加载遮罩层，防止用户重复点击
    
    // 直接让当前窗口跳转到 Laravel API 对应的 Socialite 重定向地址
    // 并将传入的大写首字母参数转成小写（例如 Google -> google）
    window.location.href = `http://localhost:8000/api/auth/${provider.toLowerCase()}`;
  };

  return (
    <>
      {isLoading && (
        <LoadingOverlay 
          isFullScreen={true} 
          title="Logging in"
          description="Verifying your information, please wait..."
        />
      )}
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex items-center justify-center p-4 relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-0 left-0 w-72 h-72 bg-orange-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
          <div className="absolute top-0 right-0 w-72 h-72 bg-red-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse" style={{animationDelay: "2s"}}></div>
          <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-72 h-72 bg-orange-300 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse" style={{animationDelay: "4s"}}></div>
        </div>

        <div className="w-full max-w-md relative z-10">
          <div className="shadow-2xl bg-white/95 backdrop-blur-sm border-0 rounded-3xl overflow-hidden">
            <div className="p-5 bg-gradient-to-r from-orange-500 to-red-500 text-white relative">
              <div className="absolute inset-0 bg-black/10"></div>
              <div className="relative z-10">
                <div className="flex items-center gap-3 mb-0 pt-2">
                  <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center flex-shrink-0 border border-white/30">
                    <LogIn className="h-6 w-6 text-white" />
                  </div>
                  <h2 className="text-2xl font-bold tracking-tight">
                    Login Account
                  </h2>
                </div>
              </div>
            </div>

            <div className="p-6">
              <div className="bg-blue-50/50 rounded-2xl p-5 mb-3 border border-blue-100/50">
                <form onSubmit={handleSubmit} className="space-y-2">
                  <div className="space-y-1">
                    <label htmlFor="email" className="block text-sm font-semibold text-gray-700 ml-1">
                      Email
                    </label>
                    <div className="relative">
                      <Mail className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                      <Input
                        id="email"
                        name="email"
                        type="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="ahpin7762@gmail.com"
                        className="pl-10 h-12 bg-white border-gray-200 focus:border-orange-500 focus:ring-orange-500/20 rounded-xl w-full text-base"
                        required
                        autoComplete="email"
                      />
                    </div>
                    {errors.email && (
                      <p className="text-xs text-red-500 mt-1">{errors.email[0]}</p>
                    )}
                  </div>

                  <div className="space-y-1">
                    <label htmlFor="password" className="block text-sm font-semibold text-gray-700 ml-1">
                      Password
                    </label>
                    <div className="relative">
                      <Lock className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                      <Input
                        id="password"
                        name="password"
                        type={showPassword ? "text" : "password"}
                        value={formData.password}
                        onChange={handleChange}
                        placeholder="••••••••••"
                        className="pl-10 pr-10 h-12 bg-white border-gray-200 focus:border-orange-500 focus:ring-orange-500/20 rounded-xl w-full text-lg tracking-widest font-bold"
                        required
                        autoComplete="current-password"
                      />
                      <button
                        type="button"
                        className="absolute right-0 top-0 h-full px-3.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-r-xl transition-colors"
                        onClick={() => setShowPassword(!showPassword)}
                      >
                        {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                      </button>
                    </div>
                  </div>
                  {errors.password && (
                    <p className="text-xs text-red-500 mt-1">{errors.password[0]}</p>
                  )}

                  <div className="flex items-center justify-between pt-2 pb-2">
                    <label className="flex items-center space-x-2.5 cursor-pointer hover:bg-black/5 p-1 -ml-1 rounded-lg transition-colors">
                      <input
                        type="checkbox"
                        id="rememberMe"
                        name="rememberMe"
                        checked={formData.rememberMe}
                        onChange={handleChange}
                        className="w-4 h-4 rounded border-gray-300 text-orange-500 focus:ring-orange-500"
                      />
                      <span className="text-sm text-gray-500 font-medium">
                        Remember Me
                      </span>
                    </label>
                    <button type="button" className="text-sm font-bold text-orange-500 hover:text-orange-600 transition-colors">
                      Forgot Password?
                    </button>
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-[#f84d28] hover:bg-[#e63f1b] text-white font-bold py-3.5 rounded-xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] shadow-md disabled:opacity-50"
                    disabled={isLoading}
                  >
                    Login
                  </button>
                </form>
              </div>

              <div className="bg-orange-50/50 rounded-xl p-4 mb-5 border border-orange-100/50">
                <div className="text-center">
                  <p className="text-sm text-gray-500 font-medium tracking-wide">
                    Don't Have An Account?{" "}
                    <Link href="/register" className="text-orange-500 hover:text-orange-600 font-bold transition-colors">
                      Click To Register
                    </Link>
                  </p>
                </div>
              </div>

              <div className="bg-white rounded-2xl p-5 border border-gray-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.1)]">
                <div className="relative mb-5">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-gray-200" />
                  </div>
                  <div className="relative flex justify-center text-sm">
                    <span className="px-4 bg-white text-gray-500 font-medium">
                      Or
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <button onClick={() => handleSocialLoginClick('Google')} type="button" className="w-full flex items-center justify-center gap-2 py-3 px-4 bg-white hover:bg-gray-50 rounded-xl border border-gray-200 transition-all duration-200 text-sm font-bold text-gray-700 shadow-sm">
                    <svg className="w-4 h-4" viewBox="0 0 24 24">
                      <path fill="#4285f4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                      <path fill="#34a853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                      <path fill="#fbbc05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                      <path fill="#ea4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                    </svg>
                    Google
                  </button>
                  <button onClick={() => handleSocialLoginClick('Facebook')} type="button" className="w-full flex items-center justify-center gap-2 py-3 px-4 bg-white hover:bg-gray-50 rounded-xl border border-gray-200 transition-all duration-200 text-sm font-bold text-gray-700 shadow-sm">
                    <svg className="w-4 h-4" fill="#1877f2" viewBox="0 0 24 24">
                      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                    </svg>
                    Facebook
                  </button>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </>
  );
}
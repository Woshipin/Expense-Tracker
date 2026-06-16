"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Eye,
  EyeOff,
  User,
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

export default function RegisterPage() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [toast, setToast] = useState<{message:string, type:'error'|'success'} | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
  });
  const [errors, setErrors] = useState<any>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setIsLoading(true);
    setErrors({});

    try {
      const response = await api.post("/register", {
        full_name: formData.name, 
        email: formData.email,
        password: formData.password,
      });

      setToast({ message: "Registration successful! Redirecting to login...", type: "success" });
      
      // 【修改】等待 1.5 秒后跳转
      setTimeout(() => {
        router.push("/login");
      }, 1500);

    } catch (error: any) {
      setIsLoading(false);
      
      if (error.response) {
        if (error.response.status === 422) {
          const backendErrors = error.response.data.errors;
          if (backendErrors.full_name) {
             backendErrors.name = backendErrors.full_name;
             delete backendErrors.full_name;
          }
          setErrors(backendErrors);
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

  return (
    <>
      {isLoading && (
        <LoadingOverlay
          isFullScreen={true}
          title="Creating Account"
          description="Setting up your account, please wait..."
        />
      )}
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex items-center justify-center p-4 relative overflow-hidden py-2">
        <div className="absolute inset-0">
          <div className="absolute top-0 left-0 w-72 h-72 bg-orange-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
          <div className="absolute top-0 right-0 w-72 h-72 bg-red-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse" style={{ animationDelay: "2s" }}></div>
          <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-72 h-72 bg-orange-300 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse" style={{ animationDelay: "4s" }}></div>
        </div>

        <div className="w-full max-w-md relative z-10">
          <div className="shadow-2xl bg-white/95 backdrop-blur-sm border-0 rounded-3xl overflow-hidden">
            <div className="p-5 bg-gradient-to-r from-orange-500 to-red-500 text-white relative">
              <div className="absolute inset-0 bg-black/10"></div>
              <div className="relative z-10">
                <div className="flex items-center gap-3 mb-0 pt-2">
                  <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border border-white/30 flex-shrink-0">
                    <User className="h-6 w-6 text-white" />
                  </div>
                  <h2 className="text-2xl font-bold tracking-tight">
                    Register Account
                  </h2>
                </div>
              </div>
            </div>

            <div className="p-6">
              <form onSubmit={handleSubmit} className="space-y-4">
                
                {/* Personal Information */}
                <div className="bg-blue-50/50 rounded-2xl p-5 border border-blue-100/50">
                  <h3 className="text-[14px] font-bold text-gray-700 mb-4 flex items-center">
                    <User className="h-4 w-4 mr-2 text-blue-500" />
                    Personal Information
                  </h3>
                  <div className="space-y-2">
                    <div className="space-y-1">
                      <label htmlFor="name" className="block text-xs font-semibold text-gray-600 ml-1">Full Name</label>
                      <div className="relative">
                        <User className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          id="name"
                          name="name"
                          type="text"
                          value={formData.name}
                          onChange={handleChange}
                          placeholder="Enter Your Name"
                          className="pl-10 h-11 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full text-sm"
                          required
                        />
                      </div>
                      {errors.name && <p className="text-xs text-red-500 mt-1">{errors.name[0]}</p>}
                    </div>

                    <div className="space-y-1">
                      <label htmlFor="email" className="block text-xs font-semibold text-gray-600 ml-1">Email</label>
                      <div className="relative">
                        <Mail className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          id="email"
                          name="email"
                          type="email"
                          value={formData.email}
                          onChange={handleChange}
                          placeholder="your@email.com"
                          className="pl-10 h-11 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full text-sm"
                          required
                        />
                      </div>
                      {errors.email && <p className="text-xs text-red-500 mt-1">{errors.email[0]}</p>}
                    </div>
                  </div>
                </div>

                {/* Password Settings */}
                {/* 【修改】将 p-3 改成了 p-5 与上面对齐 */}
                <div className="bg-emerald-50/50 rounded-2xl p-5 border border-emerald-100/50 relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-100/30 rounded-full blur-xl -translate-y-1/2 translate-x-1/2"></div>
                  <h3 className="text-[14px] font-bold text-gray-700 mb-4 flex items-center relative z-10">
                    <Lock className="h-4 w-4 mr-2 text-emerald-500" />
                    Password Settings
                  </h3>
                  {/* 【修改】将 space-y-3.5 改成了 space-y-2 与上面对齐 */}
                  <div className="space-y-2 relative z-10">
                    <div className="space-y-1">
                      <label htmlFor="password" className="block text-xs font-semibold text-gray-600 ml-1">Password</label>
                      <div className="relative">
                        <Lock className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          id="password"
                          name="password"
                          type={showPassword ? "text" : "password"}
                          value={formData.password}
                          onChange={handleChange}
                          placeholder="••••••••"
                          className="pl-10 pr-10 h-11 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full text-lg tracking-widest font-bold"
                          required
                        />
                        <button
                          type="button"
                          className="absolute right-0 top-0 h-full px-3.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-r-xl transition-colors"
                          onClick={() => setShowPassword(!showPassword)}
                        >
                          {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </button>
                      </div>
                      {errors.password && <p className="text-xs text-red-500 mt-1">{errors.password[0]}</p>}
                    </div>
                  </div>
                </div>

                <div className="p-2 rounded-xl">
                    <button
                      type="submit"
                      className="w-full bg-[#f84d28] hover:bg-[#e63f1b] text-white font-bold py-3.5 rounded-xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] shadow-md disabled:opacity-50"
                      disabled={isLoading}
                    >
                      Register
                    </button>
                </div>

              </form>

              <div className="mt-5 text-center text-sm w-full bg-orange-50/50 p-3.5 rounded-xl border border-orange-100/50">
                <p className="text-gray-500 font-medium tracking-wide">
                  Already Have An Account?{" "}
                  <Link href="/login" className="text-orange-500 hover:text-orange-600 font-bold transition-colors">
                    Click To Login
                  </Link>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
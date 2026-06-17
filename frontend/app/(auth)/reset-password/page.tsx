"use client";

import React, { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Lock, Eye, EyeOff, Loader2, CheckCircle2 } from "lucide-react";
import { Input, Toast } from "@/components/ui";
import api from "@/lib/axios";

export default function ResetPasswordPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  // 从 URL 中提取 Laravel 邮件里附带的 token 和 email
  const token = searchParams.get("token");
  const email = searchParams.get("email");

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [toast, setToast] = useState<{message:string, type:'error'|'success'} | null>(null);
  
  const [formData, setFormData] = useState({
    password: "",
    password_confirmation: "",
  });

  // 如果 URL 缺少必要的参数，直接报错
  useEffect(() => {
    if (!token || !email) {
      setToast({ message: "Invalid or missing password reset token.", type: "error" });
    }
  }, [token, email]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !email) return;
    
    setIsLoading(true);

    try {
      await api.post("/reset-password", {
        token,
        email,
        password: formData.password,
        password_confirmation: formData.password_confirmation,
      });

      setIsSuccess(true);
      setToast({ message: "Password reset successful! Redirecting...", type: "success" });
      
      setTimeout(() => {
        router.push("/login");
      }, 2000);

    } catch (error: any) {
      if (error.response && error.response.data.message) {
        setToast({ message: error.response.data.message, type: "error" });
      } else {
        setToast({ message: "Failed to reset password. The link might be expired.", type: "error" });
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex items-center justify-center p-4">
        <div className="w-full max-w-md relative z-10">
          <div className="shadow-2xl bg-white/95 backdrop-blur-sm border-0 rounded-3xl overflow-hidden">
            <div className="p-6 bg-gradient-to-r from-orange-500 to-red-500 text-white">
              <h2 className="text-2xl font-bold tracking-tight">Create New Password</h2>
              <p className="text-orange-50 text-sm mt-2 opacity-90">
                Please enter your new password below.
              </p>
            </div>

            <div className="p-6">
              {isSuccess ? (
                <div className="text-center py-6 animate-in zoom-in duration-300">
                  <CheckCircle2 className="w-16 h-16 text-green-500 mx-auto mb-4" />
                  <h3 className="text-xl font-bold text-gray-800">Password Updated!</h3>
                  <p className="text-gray-500 mt-2 text-sm">Redirecting you to login page...</p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="bg-emerald-50/50 rounded-2xl p-5 border border-emerald-100/50 space-y-4">
                    
                    {/* 新密码 */}
                    <div className="space-y-1">
                      <label className="block text-sm font-semibold text-gray-700 ml-1">New Password</label>
                      <div className="relative">
                        <Lock className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          type={showPassword ? "text" : "password"}
                          value={formData.password}
                          onChange={(e) => setFormData({...formData, password: e.target.value})}
                          placeholder="••••••••"
                          className="pl-10 pr-10 h-12 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full"
                          required minLength={6}
                        />
                        <button type="button" className="absolute right-0 top-0 h-full px-3.5 text-gray-400" onClick={() => setShowPassword(!showPassword)}>
                          {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </button>
                      </div>
                    </div>

                    {/* 确认新密码 */}
                    <div className="space-y-1">
                      <label className="block text-sm font-semibold text-gray-700 ml-1">Confirm Password</label>
                      <div className="relative">
                        <Lock className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          type={showConfirmPassword ? "text" : "password"}
                          value={formData.password_confirmation}
                          onChange={(e) => setFormData({...formData, password_confirmation: e.target.value})}
                          placeholder="••••••••"
                          className="pl-10 pr-10 h-12 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full"
                          required minLength={6}
                        />
                        <button type="button" className="absolute right-0 top-0 h-full px-3.5 text-gray-400" onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                          {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </button>
                      </div>
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full flex items-center justify-center bg-[#f84d28] hover:bg-[#e63f1b] text-white font-bold py-3.5 rounded-xl shadow-md disabled:opacity-50"
                    disabled={isLoading || !token}
                  >
                    {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Reset Password"}
                  </button>
                </form>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
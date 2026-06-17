"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Mail, Loader2 } from "lucide-react";
import { Input, Toast } from "@/components/ui";
import api from "@/lib/axios";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [toast, setToast] = useState<{message:string, type:'error'|'success'} | null>(null);
  const [isSent, setIsSent] = useState(false); // 标记是否发送成功

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await api.post("/forgot-password", { email });
      setIsSent(true);
      setToast({ message: "Reset link sent to your email!", type: "success" });
    } catch (error: any) {
      if (error.response && error.response.data.message) {
        setToast({ message: error.response.data.message, type: "error" });
      } else {
        setToast({ message: "Failed to send reset link. Please try again.", type: "error" });
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex items-center justify-center p-4 relative overflow-hidden">
        {/* 背景光晕装饰 */}
        <div className="absolute inset-0">
          <div className="absolute top-0 left-0 w-72 h-72 bg-orange-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
          <div className="absolute top-0 right-0 w-72 h-72 bg-red-200 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse" style={{animationDelay: "2s"}}></div>
        </div>

        <div className="w-full max-w-md relative z-10">
          <Link href="/login" className="inline-flex items-center text-sunset-dark hover:text-orange-600 mb-6 font-semibold transition-colors">
            <ArrowLeft className="w-4 h-4 mr-2" /> Back to Login
          </Link>

          <div className="shadow-2xl bg-white/95 backdrop-blur-sm border-0 rounded-3xl overflow-hidden">
            <div className="p-6 bg-gradient-to-r from-orange-500 to-red-500 text-white relative">
              <div className="absolute inset-0 bg-black/10"></div>
              <div className="relative z-10">
                <h2 className="text-2xl font-bold tracking-tight">Forgot Password</h2>
                <p className="text-orange-50 text-sm mt-2 opacity-90">
                  Enter your email address and we'll send you a link to reset your password.
                </p>
              </div>
            </div>

            <div className="p-6">
              {!isSent ? (
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="bg-blue-50/50 rounded-2xl p-5 border border-blue-100/50">
                    <div className="space-y-1">
                      <label htmlFor="email" className="block text-sm font-semibold text-gray-700 ml-1">
                        Email Address
                      </label>
                      <div className="relative">
                        <Mail className="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                        <Input
                          id="email"
                          type="email"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          placeholder="your@email.com"
                          className="pl-10 h-12 bg-white border-gray-200 focus:border-orange-500 rounded-xl w-full"
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full flex items-center justify-center bg-[#f84d28] hover:bg-[#e63f1b] text-white font-bold py-3.5 rounded-xl transition-all shadow-md disabled:opacity-50"
                    disabled={isLoading}
                  >
                    {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Send Reset Link"}
                  </button>
                </form>
              ) : (
                <div className="text-center py-6">
                  <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Mail className="w-8 h-8 text-green-500" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-800 mb-2">Check your email</h3>
                  <p className="text-gray-500 text-sm">
                    We have sent a password reset link to <strong>{email}</strong>. 
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
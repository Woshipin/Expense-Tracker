"use client";

import { Card, Button, Input, Toast } from "@/components/ui";
import { User, Mail, Lock, Loader2, Eye, EyeOff, Image, X, ShieldCheck } from "lucide-react";
import React, { useState, useEffect } from "react";
import api from "@/lib/axios";

// ------------------------------------
// UI 组件：全局统一的颜色标签
// ------------------------------------
const RoleBadge = ({ role }: { role: any }) => {
  switch (String(role)) {
    case '0': return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-purple-50 text-purple-600">SuperAdmin</span>;
    case '1': return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-indigo-50 text-indigo-600">Admin</span>;
    case '2': return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-amber-50 text-amber-600">Premium User</span>;
    case '3': return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-slate-100 text-slate-600">Basic User</span>;
    default: return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-gray-50 text-gray-600">Unknown</span>;
  }
};

const StatusBadge = ({ status }: { status: any }) => {
  return String(status) === '1'
    ? <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-green-50 text-green-600">Active</span>
    : <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-red-50 text-red-600">Inactive</span>;
};

const ProviderBadge = ({ provider }: { provider: any }) => {
  if (!provider) return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-blue-50 text-blue-600">Standard</span>;
  if (provider === 'google') return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-red-50 text-red-600">Google</span>;
  if (provider === 'facebook') return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-blue-100 text-blue-700">Facebook</span>;
  return <span className="inline-flex py-1.5 px-3 rounded-lg text-[10px] sm:text-xs font-bold bg-gray-50 text-gray-600 capitalize">{provider}</span>;
};

const getInitials = (name: string) => {
  if (!name) return "U";
  return name.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2);
};

export default function ProfilePage() {
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // UI 状态
  const [isEditProfile, setIsEditProfile] = useState(false);
  const [isChangePassword, setIsChangePassword] = useState(false);
  
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  
  // 数据与加载状态
  const [user, setUser] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // 表单状态
  const [profileForm, setProfileForm] = useState({ full_name: "", email: "" });
  const [passwordForm, setPasswordForm] = useState({ current_password: "", new_password: "", new_password_confirmation: "" });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreviewState, setImagePreviewState] = useState<string | null>(null); 
  const [errors, setErrors] = useState<any>({});

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchUser = async () => {
    try {
      const response = await api.get('/me');
      setUser(response.data);
      setProfileForm({
        full_name: response.data.full_name,
        email: response.data.email
      });
      setImagePreviewState(response.data.image_path || null);
    } catch (error) {
      showToast("Failed to load profile data", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUser();
  }, []);

  const openEditModal = () => {
    setErrors({});
    setSelectedFile(null);
    setImagePreviewState(user?.image_path || null);
    setProfileForm({ full_name: user?.full_name || "", email: user?.email || "" });
    setIsEditProfile(true);
  };

  const openPasswordModal = () => {
    setErrors({});
    setPasswordForm({ current_password: "", new_password: "", new_password_confirmation: "" });
    setShowCurrentPassword(false);
    setShowNewPassword(false);
    setShowConfirmPassword(false);
    setIsChangePassword(true);
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      setImagePreviewState(URL.createObjectURL(file)); 
    }
  };

  const handleUpdateProfile = async () => {
    setIsSaving(true);
    setErrors({});
    
    // 使用 FormData 以支持图片上传
    const data = new FormData();
    data.append('full_name', profileForm.full_name);
    data.append('email', profileForm.email);
    if (selectedFile) {
      data.append('image', selectedFile);
    }
    // Laravel 对于带有 File 的 PUT 请求需要伪造为 POST
    data.append('_method', 'PUT');

    try {
      const response = await api.post('/profile', data, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setUser(response.data.user); 
      setIsEditProfile(false);
      showToast("Profile details updated successfully!");
    } catch (error: any) {
      if (error.response && error.response.status === 422) {
        setErrors(error.response.data.errors);
      } else {
        showToast("Failed to update profile", "error");
      }
    } finally {
      setIsSaving(false);
    }
  };

  const handlePasswordChange = async () => {
    setIsSaving(true);
    setErrors({});
    try {
      await api.put('/profile/password', passwordForm);
      setIsChangePassword(false);
      setPasswordForm({ current_password: "", new_password: "", new_password_confirmation: "" }); 
      showToast("Password changed securely.");
    } catch (error: any) {
      if (error.response && error.response.status === 422) {
        setErrors(error.response.data.errors);
      } else {
        showToast(error.response?.data?.error || "Failed to change password", "error");
      }
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[50vh]">
        <Loader2 className="w-8 h-8 text-sunset-primary animate-spin" />
      </div>
    );
  }

  return (
    // 使用 Fragment 包裹，彻底解决 Z-index 层叠被动画破坏的问题
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}
      
      {/* ===============================
          修改资料 Modal (全端自适应设计，iPad/Mobile绝对居中覆盖)
      =============================== */}
      {isEditProfile && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg sm:max-w-xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">Edit Profile</h2>
              <button onClick={() => setIsEditProfile(false)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1 bg-blue-50/20">
              <div className="space-y-5 sm:space-y-6">
                
                {/* 头像上传区域 */}
                <div className="flex flex-col sm:flex-row items-center gap-4 sm:gap-6 bg-white p-4 sm:p-5 rounded-[1.5rem] border border-blue-100/50 shadow-sm">
                  {imagePreviewState ? (
                    <img src={imagePreviewState} alt="Preview" className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl sm:rounded-[1.5rem] object-cover border-2 border-orange-500/20 shadow-sm shrink-0" />
                  ) : (
                    <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl sm:rounded-[1.5rem] bg-gray-50 border border-dashed border-gray-300 flex flex-col items-center justify-center text-gray-400 shrink-0">
                      <Image size={24} className="mb-1 text-gray-300" />
                      <span className="text-[10px] font-bold text-gray-400">Empty</span>
                    </div>
                  )}
                  <div className="w-full">
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1.5 block">Update Avatar</label>
                    <input 
                      type="file" accept="image/*" onChange={handleImageChange}
                      className="w-full bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-xl px-3 sm:px-4 py-2 sm:py-3 text-xs sm:text-sm text-sunset-dark focus:outline-none cursor-pointer transition-colors"
                    />
                    {errors.image && <p className="text-xs text-red-500 mt-1 pl-1">{errors.image[0]}</p>}
                  </div>
                </div>

                <div>
                  <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1.5 block">Full Name</label>
                  <Input 
                    value={profileForm.full_name} 
                    onChange={(e) => setProfileForm({...profileForm, full_name: e.target.value})} 
                    className="h-11 sm:h-12 bg-white"
                    autoComplete="off"
                  />
                  {errors.full_name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.full_name[0]}</p>}
                </div>

                <div>
                  <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1.5 block">Email Address</label>
                  <Input 
                    type="email" 
                    value={profileForm.email} 
                    onChange={(e) => setProfileForm({...profileForm, email: e.target.value})} 
                    className="h-11 sm:h-12 bg-white"
                    autoComplete="new-email"
                  />
                  {errors.email && <p className="text-xs text-red-500 mt-1 pl-1">{errors.email[0]}</p>}
                </div>

              </div>
            </div>

            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-11 text-xs sm:text-sm" onClick={() => setIsEditProfile(false)}>Cancel</Button>
              <Button onClick={handleUpdateProfile} disabled={isSaving} className="flex-1 sm:flex-none px-8 h-11 text-xs sm:text-sm shadow-md">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* ===============================
          修改密码 Modal (全端自适应设计，iPad/Mobile绝对居中覆盖)
      =============================== */}
      {isChangePassword && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg sm:max-w-xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0 bg-emerald-50/30">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">Change Password</h2>
              <button onClick={() => setIsChangePassword(false)} className="p-2 bg-white hover:bg-gray-100 rounded-full text-gray-500 transition-colors shadow-sm">
                <X size={20} />
              </button>
            </div>

            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1 bg-emerald-50/10">
              <div className="space-y-4 sm:space-y-5">
                
                <div>
                  <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1.5 block">Current Password</label>
                  <div className="relative">
                    <Input 
                      type={showCurrentPassword ? "text" : "password"} 
                      placeholder="••••••••" 
                      value={passwordForm.current_password}
                      onChange={(e) => setPasswordForm({...passwordForm, current_password: e.target.value})}
                      className="pr-10 h-11 sm:h-12 bg-white"
                      autoComplete="new-password"
                    />
                    <button type="button" className="absolute right-0 top-0 h-full px-4 text-gray-400 hover:text-gray-600 transition-colors" onClick={() => setShowCurrentPassword(!showCurrentPassword)}>
                      {showCurrentPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {errors.current_password && <p className="text-xs text-red-500 mt-1 pl-1">{errors.current_password[0]}</p>}
                </div>
                
                <div className="border-t border-emerald-500/10 py-1"></div>
                
                <div>
                  <label className="text-[10px] sm:text-xs font-bold text-emerald-700/70 uppercase tracking-widest pl-1 mb-1.5 block">New Password</label>
                  <div className="relative">
                    <Input 
                      type={showNewPassword ? "text" : "password"} 
                      placeholder="••••••••" 
                      value={passwordForm.new_password}
                      onChange={(e) => setPasswordForm({...passwordForm, new_password: e.target.value})}
                      className="pr-10 h-11 sm:h-12 bg-white border-emerald-200 focus:ring-emerald-500/20"
                      autoComplete="new-password"
                    />
                    <button type="button" className="absolute right-0 top-0 h-full px-4 text-gray-400 hover:text-emerald-600 transition-colors" onClick={() => setShowNewPassword(!showNewPassword)}>
                      {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {errors.new_password && <p className="text-xs text-red-500 mt-1 pl-1">{errors.new_password[0]}</p>}
                </div>
                
                <div>
                  <label className="text-[10px] sm:text-xs font-bold text-emerald-700/70 uppercase tracking-widest pl-1 mb-1.5 block">Confirm New Password</label>
                  <div className="relative">
                    <Input 
                      type={showConfirmPassword ? "text" : "password"} 
                      placeholder="••••••••" 
                      value={passwordForm.new_password_confirmation}
                      onChange={(e) => setPasswordForm({...passwordForm, new_password_confirmation: e.target.value})}
                      className="pr-10 h-11 sm:h-12 bg-white border-emerald-200 focus:ring-emerald-500/20"
                      autoComplete="new-password"
                    />
                    <button type="button" className="absolute right-0 top-0 h-full px-4 text-gray-400 hover:text-emerald-600 transition-colors" onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                      {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

              </div>
            </div>

            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-emerald-500/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-emerald-50/30 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-11 text-xs sm:text-sm text-emerald-800 hover:bg-emerald-100" onClick={() => setIsChangePassword(false)}>Cancel</Button>
              <Button onClick={handlePasswordChange} disabled={isSaving} className="flex-1 sm:flex-none px-8 h-11 text-xs sm:text-sm bg-emerald-500 hover:bg-emerald-600 shadow-md shadow-emerald-500/20 text-white border-0">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Updating..." : "Update Password"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* ===============================
          主页面内容区 (被包含在动画层内)
      =============================== */}
      <div className="space-y-4 sm:space-y-6 animate-in fade-in zoom-in-95 duration-300 relative z-0 pb-10">
        <header>
          <h1 className="text-2xl font-bold text-sunset-dark">Profile</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage your personal information and security settings.</p>
        </header>

        <Card className="p-0 overflow-hidden shadow-xl shadow-orange-500/5 border-2 border-orange-500/20 rounded-[24px]">
          {/* 核心内容区：响应式双列/单列排版 */}
          <div className="flex flex-col lg:flex-row">
             
             {/* 左侧区域：头像展示 */}
             <div className="p-6 sm:p-10 lg:w-5/12 flex flex-col items-center justify-center bg-gradient-to-b from-orange-50/50 to-white border-b lg:border-b-0 lg:border-r border-orange-500/10">
                <div className="relative mb-6">
                  {user?.image_path ? (
                    <img 
                      src={user.image_path} 
                      alt="Profile Avatar" 
                      className="w-32 h-32 sm:w-40 sm:h-40 rounded-[2rem] sm:rounded-[2.5rem] object-cover shadow-xl border-4 border-white shrink-0"
                      referrerPolicy="no-referrer"
                    />
                  ) : (
                    <div className="w-32 h-32 sm:w-40 sm:h-40 rounded-[2rem] sm:rounded-[2.5rem] bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white flex items-center justify-center font-bold text-5xl sm:text-6xl shadow-xl border-4 border-white shrink-0">
                      {getInitials(user?.full_name)}
                    </div>
                  )}
                  <div className="absolute -bottom-3 left-1/2 -translate-x-1/2 whitespace-nowrap">
                    <RoleBadge role={user?.role} />
                  </div>
                </div>
                <h2 className="text-2xl sm:text-3xl font-black text-sunset-dark text-center leading-tight">{user?.full_name}</h2>
                <p className="text-sm font-medium text-sunset-dark/50 mt-1 text-center">{user?.email}</p>
             </div>

             {/* 右侧区域：详细资料 */}
             <div className="p-6 sm:p-10 lg:w-7/12 flex flex-col justify-center gap-6 sm:gap-8 bg-white">
                
                <div className="space-y-6">
                   <div>
                      <label className="text-[10px] sm:text-xs font-black text-sunset-dark/40 uppercase tracking-widest block mb-1.5 flex items-center gap-1.5">
                        <ShieldCheck size={14} className="text-blue-500" /> Channel / Provider
                      </label>
                      <ProviderBadge provider={user?.provider} />
                   </div>
                   
                   <div>
                      <label className="text-[10px] sm:text-xs font-black text-sunset-dark/40 uppercase tracking-widest block mb-1.5 flex items-center gap-1.5">
                        <Lock size={14} className="text-purple-500" /> System Role
                      </label>
                      <span className="font-bold text-sunset-dark text-base sm:text-lg">
                        {String(user?.role) === '0' ? 'Super Administrator' : 
                         String(user?.role) === '1' ? 'Administrator' : 
                         String(user?.role) === '2' ? 'Premium Subscriber' : 'Standard Basic User'}
                      </span>
                   </div>

                   <div>
                      <label className="text-[10px] sm:text-xs font-black text-sunset-dark/40 uppercase tracking-widest block mb-1.5 flex items-center gap-1.5">
                        <User size={14} className="text-green-500" /> Account Status
                      </label>
                      <StatusBadge status={user?.status} />
                   </div>
                </div>

             </div>
          </div>

          {/* 底部按钮操作区 */}
          <div className="p-5 sm:p-6 lg:px-10 border-t border-orange-500/10 flex flex-col sm:flex-row gap-3 sm:gap-4 bg-gray-50/50">
            <Button onClick={openEditModal} className="flex-1 py-3 sm:py-6 text-sm shadow-md">
              <User size={18} className="mr-2 inline" /> Edit Profile & Avatar
            </Button>
            
            {!user?.provider ? (
              <Button variant="secondary" onClick={openPasswordModal} className="flex-1 py-3 sm:py-6 text-sm border-gray-200 bg-white hover:bg-gray-50 shadow-sm">
                <Lock size={18} className="mr-2 inline text-sunset-primary" /> Change Security Password
              </Button>
            ) : (
              <Button variant="secondary" disabled className="flex-1 py-3 sm:py-6 text-sm opacity-50 cursor-not-allowed bg-gray-100">
                <Lock size={18} className="mr-2 inline text-gray-400" /> Password Managed via {user.provider.charAt(0).toUpperCase() + user.provider.slice(1)}
              </Button>
            )}
          </div>
        </Card>
      </div>
    </>
  );
}
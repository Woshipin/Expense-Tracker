"use client";

import { Card, Button, Input, Modal, Toast } from "@/components/ui";
// 【修改】引入了 Eye 和 EyeOff 图标
import { User, Mail, Lock, Loader2, Eye, EyeOff } from "lucide-react";
import { useState, useEffect } from "react";
import api from "@/lib/axios";

export default function ProfilePage() {
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // UI 状态
  const [isEditProfile, setIsEditProfile] = useState(false);
  const [isChangePassword, setIsChangePassword] = useState(false);
  
  // 【新增】控制密码显示/隐藏的状态
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
    } catch (error) {
      showToast("Failed to load profile data", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUser();
  }, []);

  const handleUpdateProfile = async () => {
    setIsSaving(true);
    setErrors({});
    try {
      const response = await api.put('/profile', profileForm);
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

  const getRoleName = (role: number) => {
    switch(role) {
      case 0: return 'Super Admin';
      case 1: return 'Admin';
      case 2: return 'Premium';
      case 3: return 'Basic';
      default: return 'User';
    }
  };

  const getInitials = (name: string) => {
    if (!name) return "U";
    const parts = name.split(" ");
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[50vh]">
        <Loader2 className="w-8 h-8 text-sunset-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 max-w-3xl mx-auto pb-4">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      {/* 修改资料 Modal */}
      <Modal isOpen={isEditProfile} onClose={() => setIsEditProfile(false)} title="Edit Profile Details">
         <div className="space-y-4">
            <div>
              <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Full Name</label>
              <Input 
                value={profileForm.full_name} 
                onChange={(e) => setProfileForm({...profileForm, full_name: e.target.value})} 
              />
              {errors.full_name && <p className="text-xs text-red-500 mt-1 pl-2">{errors.full_name[0]}</p>}
            </div>
            <div>
              <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Email Address</label>
              <Input 
                type="email" 
                value={profileForm.email} 
                onChange={(e) => setProfileForm({...profileForm, email: e.target.value})} 
              />
              {errors.email && <p className="text-xs text-red-500 mt-1 pl-2">{errors.email[0]}</p>}
            </div>
            <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
               <Button variant="ghost" onClick={() => setIsEditProfile(false)}>Cancel</Button>
               <Button onClick={handleUpdateProfile} disabled={isSaving}>
                 {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save Changes"}
               </Button>
            </div>
         </div>
      </Modal>

      {/* 修改密码 Modal */}
      <Modal isOpen={isChangePassword} onClose={() => setIsChangePassword(false)} title="Change Password">
         <div className="space-y-4">
            {/* 【修改】Current Password 添加眼睛图标 */}
            <div>
              <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Current Password</label>
              <div className="relative">
                <Input 
                  type={showCurrentPassword ? "text" : "password"} 
                  placeholder="••••••••" 
                  value={passwordForm.current_password}
                  onChange={(e) => setPasswordForm({...passwordForm, current_password: e.target.value})}
                  className="pr-10"
                />
                <button
                  type="button"
                  className="absolute right-0 top-0 h-full px-3.5 text-gray-400 hover:text-gray-600 transition-colors"
                  onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                >
                  {showCurrentPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {errors.current_password && <p className="text-xs text-red-500 mt-1 pl-2">{errors.current_password[0]}</p>}
            </div>
            
            <div className="border-t border-sunset-primary/5 py-1"></div>
            
            {/* 【修改】New Password 添加眼睛图标 */}
            <div>
              <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">New Password</label>
              <div className="relative">
                <Input 
                  type={showNewPassword ? "text" : "password"} 
                  placeholder="••••••••" 
                  value={passwordForm.new_password}
                  onChange={(e) => setPasswordForm({...passwordForm, new_password: e.target.value})}
                  className="pr-10"
                />
                <button
                  type="button"
                  className="absolute right-0 top-0 h-full px-3.5 text-gray-400 hover:text-gray-600 transition-colors"
                  onClick={() => setShowNewPassword(!showNewPassword)}
                >
                  {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {errors.new_password && <p className="text-xs text-red-500 mt-1 pl-2">{errors.new_password[0]}</p>}
            </div>
            
            {/* 【修改】Confirm New Password 添加眼睛图标 */}
            <div>
              <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Confirm New Password</label>
              <div className="relative">
                <Input 
                  type={showConfirmPassword ? "text" : "password"} 
                  placeholder="••••••••" 
                  value={passwordForm.new_password_confirmation}
                  onChange={(e) => setPasswordForm({...passwordForm, new_password_confirmation: e.target.value})}
                  className="pr-10"
                />
                <button
                  type="button"
                  className="absolute right-0 top-0 h-full px-3.5 text-gray-400 hover:text-gray-600 transition-colors"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
               <Button variant="ghost" onClick={() => setIsChangePassword(false)}>Cancel</Button>
               <Button onClick={handlePasswordChange} disabled={isSaving}>
                 {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : "Update Password"}
               </Button>
            </div>
         </div>
      </Modal>

      <header>
        <h1 className="text-2xl font-bold text-sunset-dark">Profile</h1>
        <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage your personal information and application settings.</p>
      </header>

      <Card className="flex flex-col md:flex-row items-center md:items-start gap-8 shadow-md shadow-black/5 p-6 md:p-8">
        {user?.image_path ? (
          <img 
            src={user.image_path} 
            alt="Profile Avatar" 
            className="w-28 h-28 rounded-[2rem] object-cover shadow-lg shadow-black/10 shrink-0"
            referrerPolicy="no-referrer"
          />
        ) : (
          <div className="w-28 h-28 rounded-[2rem] bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white flex items-center justify-center font-bold text-4xl shadow-lg shadow-sunset-primary/20 shrink-0">
            {getInitials(user?.full_name)}
          </div>
        )}
        
        <div className="flex-1 w-full space-y-6">
          <div className="space-y-4">
             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><User size={20}/></div>
                <div className="overflow-hidden">
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Full Name</span>
                   <span className="font-black text-lg text-sunset-dark block truncate">{user?.full_name}</span>
                </div>
             </div>
             
             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><Mail size={20}/></div>
                <div className="overflow-hidden">
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Email Address</span>
                   <span className="font-black text-lg text-sunset-dark block truncate">{user?.email}</span>
                </div>
             </div>

             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><Lock size={20}/></div>
                <div>
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Role</span>
                   <span className="font-black text-lg text-sunset-dark block">{getRoleName(user?.role)}</span>
                </div>
             </div>
          </div>
          
          <div className="border-t border-sunset-primary/10 pt-6 flex flex-col sm:flex-row gap-3">
            <Button onClick={() => setIsEditProfile(true)} className="flex-1">
              <User size={16} className="mr-2 inline" /> Edit Profile
            </Button>
            
            {!user?.provider ? (
              <Button variant="secondary" onClick={() => setIsChangePassword(true)} className="flex-1">
                <Lock size={16} className="mr-2 inline" /> Change Password
              </Button>
            ) : (
              <Button variant="secondary" disabled className="flex-1 opacity-50 cursor-not-allowed">
                <Lock size={16} className="mr-2 inline" /> Password Managed via {user.provider.charAt(0).toUpperCase() + user.provider.slice(1)}
              </Button>
            )}
          </div>
        </div>
      </Card>
    </div>
  );
}
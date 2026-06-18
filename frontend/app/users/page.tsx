"use client";

import React, { useState, useEffect } from "react";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Lock, User, Loader2, Image, X, ShieldCheck } from "lucide-react";
import api from "@/lib/axios";

interface LoadingOverlayProps {
  title?: string;
  description?: string;
  isFullScreen?: boolean;
}

const LoadingOverlay: React.FC<LoadingOverlayProps> = ({ title, description, isFullScreen = false }) => {
  const loadingContent = (
    <div className="text-center bg-white px-16 py-8 md:px-20 md:py-10 rounded-3xl shadow-2xl border border-orange-200 w-full max-w-md md:max-w-lg mx-4">
      <div className="relative inline-block">
        <Loader2 className="h-16 w-16 animate-spin text-orange-500" />
        <div className="absolute inset-0 h-16 w-16 border-4 border-orange-200 rounded-full mx-auto animate-pulse"></div>
      </div>
      <h3 className="mt-6 text-xl font-semibold text-gray-800">{title || "Loading"}</h3>
      <p className="mt-2 text-gray-600">{description || "Please wait while we load the content..."}</p>
      <div className="mt-4 flex justify-center space-x-1">
        <div className="w-2 h-2 bg-orange-400 rounded-full animate-bounce"></div>
        <div className="w-2 h-2 bg-orange-400 rounded-full animate-bounce" style={{ animationDelay: "0.1s" }}></div>
        <div className="w-2 h-2 bg-orange-400 rounded-full animate-bounce" style={{ animationDelay: "0.2s" }}></div>
      </div>
    </div>
  );

  if (isFullScreen) {
    return <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-orange-50/80 backdrop-blur-sm">{loadingContent}</div>;
  }
  return <div className="flex items-center justify-center min-h-[300px] py-10">{loadingContent}</div>;
};

// ------------------------------------
// UI 组件：状态标签 (全局统一管理颜色)
// ------------------------------------
const RoleBadge = ({ role }: { role: any }) => {
  switch (String(role)) {
    case '0': return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-purple-50 text-purple-600">SuperAdmin</span>;
    case '1': return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-indigo-50 text-indigo-600">Admin</span>;
    case '2': return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-amber-50 text-amber-600">Premium User</span>;
    case '3': return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-slate-100 text-slate-600">Basic User</span>;
    default: return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-gray-50 text-gray-600">Unknown</span>;
  }
};

const StatusBadge = ({ status }: { status: any }) => {
  return String(status) === '1'
    ? <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-green-50 text-green-600">Active</span>
    : <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-red-50 text-red-600">Inactive</span>;
};

const ProviderBadge = ({ provider }: { provider: any }) => {
  if (!provider) return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-blue-50 text-blue-600">Standard</span>;
  if (provider === 'google') return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-red-50 text-red-600">Google</span>;
  if (provider === 'facebook') return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-blue-100 text-blue-700">Facebook</span>;
  return <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-gray-50 text-gray-600 capitalize">{provider}</span>;
};

const getInitials = (name: string) => { return !name ? "U" : name.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2); };

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingUser, setViewingUser] = useState<any>(null);
  const [editingUser, setEditingUser] = useState<any>(null);
  const [deletingUser, setDeletingUser] = useState<any>(null);
  
  // Search & Filter
  const [searchQuery, setSearchQuery] = useState("");
  const [filterProvider, setFilterProvider] = useState("all");
  const [filterRole, setFilterRole] = useState("all");
  const [filterStatus, setFilterStatus] = useState("all");

  // Loading States
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Form Fields State
  const [formData, setFormData] = useState({
    full_name: "", email: "", password: "", role: "3", status: "1" 
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreviewState, setImagePreviewState] = useState<string | null>(null); 
  const [errors, setErrors] = useState<any>({});
  const [showPassword, setShowPassword] = useState(false);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const params: any = { page: currentPage };
      if (searchQuery) params.search = searchQuery;
      if (filterProvider !== "all") params.provider = filterProvider;
      if (filterRole !== "all") params.role = filterRole;
      if (filterStatus !== "all") params.status = filterStatus;

      const response = await api.get('/users', { params });
      setUsers(response.data.data);
      setTotalPages(response.data.last_page);
    } catch (error) {
      showToast("Failed to fetch users. Check backend.", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [currentPage, filterProvider, filterRole, filterStatus]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      setCurrentPage(1);
      fetchUsers();
    }, 500);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery]);

  const openAddModal = () => {
    setErrors({});
    setSelectedFile(null);
    setImagePreviewState(null);
    setFormData({ full_name: "", email: "", password: "", role: "3", status: "1" });
    setIsAddOpen(true);
  };

  const openEditModal = (u: any) => {
    setErrors({});
    setSelectedFile(null);
    setImagePreviewState(u.image_path || null); 
    setFormData({ full_name: u.full_name, email: u.email, password: "", role: String(u.role), status: String(u.status) });
    setEditingUser(u);
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      setImagePreviewState(URL.createObjectURL(file)); 
    }
  };

  const handleSaveUser = async () => {
    setIsSaving(true);
    setErrors({});
    const data = new FormData();
    data.append('full_name', formData.full_name);
    data.append('email', formData.email);
    data.append('role', formData.role);
    data.append('status', formData.status);
    if (formData.password) data.append('password', formData.password);
    if (selectedFile) data.append('image', selectedFile); 

    try {
      if (editingUser) {
        data.append('_method', 'PUT');
        await api.post(`/users/${editingUser.id}`, data, { headers: { 'Content-Type': 'multipart/form-data' } });
        showToast('User updated successfully!', 'success');
        setEditingUser(null);
      } else {
        await api.post('/users', data, { headers: { 'Content-Type': 'multipart/form-data' } });
        showToast('User added successfully!', 'success');
        setIsAddOpen(false);
      }
      fetchUsers();
    } catch (error: any) {
      if (error.response && error.response.status === 422) setErrors(error.response.data.errors);
      else showToast(error.response?.data?.error || "Operation failed. Server error 500.", "error");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      await api.delete(`/users/${deletingUser.id}`);
      showToast('User deleted successfully', 'success');
      setDeletingUser(null);
      fetchUsers();
    } catch (error: any) {
      showToast(error.response?.data?.error || "Failed to delete user", "error");
      setDeletingUser(null);
    }
  };

  return (
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. View User Modal */}
      {viewingUser && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-4xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">User Details</h2>
              <button onClick={() => setViewingUser(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 sm:gap-6 items-stretch">
                <div className="bg-blue-50/40 rounded-2xl sm:rounded-[1.5rem] p-6 border border-blue-100 flex flex-col items-center justify-center gap-4 text-center h-full relative overflow-hidden">
                  <div className="absolute top-0 w-full h-24 bg-gradient-to-b from-blue-100/50 to-transparent"></div>
                  <div className="relative z-10 shrink-0">
                    {viewingUser?.image_path ? (
                      <img src={viewingUser.image_path} alt="Avatar" className="w-24 h-24 sm:w-28 sm:h-28 rounded-[2rem] object-cover border-[3px] border-white shadow-lg" referrerPolicy="no-referrer" />
                    ) : (
                      <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-[2rem] bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white flex items-center justify-center font-bold text-4xl border-[3px] border-white shadow-lg uppercase">
                        {getInitials(viewingUser?.full_name)}
                      </div>
                    )}
                  </div>
                  <div className="relative z-10 mt-2">
                    <h3 className="font-extrabold text-sunset-dark text-xl sm:text-2xl leading-tight">{viewingUser?.full_name}</h3>
                    <p className="font-medium text-sunset-dark/60 text-sm mt-1">{viewingUser?.email}</p>
                  </div>
                </div>

                <div className="bg-emerald-50/40 rounded-2xl sm:rounded-[1.5rem] p-6 border border-emerald-100 flex flex-col justify-center h-full">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center mb-5 sm:mb-6">
                    <ShieldCheck size={18} className="mr-2 text-emerald-500" /> System & Access
                  </h3>
                  <div className="space-y-4 sm:space-y-6">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Channel / Provider</label>
                      <ProviderBadge provider={viewingUser?.provider} />
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Role Assigned</label>
                      <RoleBadge role={viewingUser?.role} />
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Account Status</label>
                      <StatusBadge status={viewingUser?.status} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex justify-end shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button onClick={() => setViewingUser(null)} className="w-full sm:w-auto px-6 sm:px-8 shadow-sm">Close Window</Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit User Modal */}
      {(isAddOpen || editingUser) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-[950px] rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingUser ? "Edit User" : "Add User"}</h2>
              <button onClick={() => { setIsAddOpen(false); setEditingUser(null); setShowPassword(false); }} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-4 sm:p-6 md:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 sm:gap-6 items-start">
                <div className="bg-blue-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-blue-100 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <User size={16} className="mr-2 text-blue-500" /> Account Information
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Full Name</label>
                    <Input placeholder="John Doe" value={formData.full_name} onChange={(e) => setFormData({...formData, full_name: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" autoComplete="off" />
                    {errors.full_name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.full_name[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Email</label>
                    <Input type="email" placeholder="john@example.com" value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" autoComplete="new-email" />
                    {errors.email && <p className="text-xs text-red-500 mt-1 pl-1">{errors.email[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1.5 block">Avatar Image (头像上传)</label>
                    <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-4">
                      {imagePreviewState ? (
                        <img src={imagePreviewState} alt="Avatar Preview" className="w-14 h-14 sm:w-16 sm:h-16 rounded-xl sm:rounded-2xl object-cover border-2 border-orange-500/20 shadow-sm shrink-0" />
                      ) : (
                        <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-xl sm:rounded-2xl bg-white border border-dashed border-gray-300 flex flex-col items-center justify-center text-gray-400 shrink-0">
                          <Image size={20} className="mb-0.5 text-gray-300" />
                          <span className="text-[9px] sm:text-[10px] font-bold text-gray-400">Empty</span>
                        </div>
                      )}
                      <input type="file" accept="image/*" onChange={handleImageChange} className="w-full bg-white border border-gray-200 rounded-xl px-3 sm:px-4 py-2 sm:py-3 text-xs sm:text-sm text-sunset-dark focus:outline-none focus:border-orange-500 cursor-pointer" />
                    </div>
                    {errors.image && <p className="text-xs text-red-500 mt-1 pl-1">{errors.image[0]}</p>}
                  </div>
                </div>

                <div className="bg-emerald-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-emerald-100 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <Lock size={16} className="mr-2 text-emerald-500" /> Credentials & Role Settings
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">
                      {editingUser ? "New Password (Optional)" : "Password"}
                    </label>
                    <div className="relative">
                      <Input type={showPassword ? "text" : "password"} placeholder="••••••••" value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})} className="pr-10 h-10 sm:h-11 text-sm bg-white" autoComplete="new-password" />
                      <button type="button" className="absolute right-0 top-0 h-full px-3 text-gray-400" onClick={() => setShowPassword(!showPassword)}>
                        {showPassword ? <Eye size={16} className="text-sunset-dark/60"/> : <Lock size={16} className="text-sunset-dark/30" />}
                      </button>
                    </div>
                    {errors.password && <p className="text-xs text-red-500 mt-1 pl-1">{errors.password[0]}</p>}
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Role</label>
                      <Select value={formData.role} onValueChange={(val) => setFormData({...formData, role: val})}>
                        <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                          <SelectValue placeholder="Select Role" />
                        </SelectTrigger>
                        <SelectContent className="z-[10050]">
                          <SelectItem value="0">SuperAdmin</SelectItem>
                          <SelectItem value="1">Admin</SelectItem>
                          <SelectItem value="2">Premium User</SelectItem>
                          <SelectItem value="3">Basic User</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Status</label>
                      <Select value={formData.status} onValueChange={(val) => setFormData({...formData, status: val})}>
                        <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                          <SelectValue placeholder="Select Status" />
                        </SelectTrigger>
                        <SelectContent className="z-[10050]">
                          <SelectItem value="1">Active (正常)</SelectItem>
                          <SelectItem value="0">Inactive (封禁)</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-10 sm:h-11 text-xs sm:text-sm" onClick={() => { setIsAddOpen(false); setEditingUser(null); setShowPassword(false); }}>Cancel</Button>
              <Button onClick={handleSaveUser} disabled={isSaving} className="flex-1 sm:flex-none px-6 sm:px-8 h-10 sm:h-11 text-xs sm:text-sm flex items-center justify-center shadow-md">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save User"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingUser && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg sm:text-xl font-bold text-red-600">Delete User</h2>
              <button onClick={() => setDeletingUser(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 sm:p-8 flex-1 overflow-y-auto">
              <p className="font-medium text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this user? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl sm:rounded-[1.5rem] border border-red-100 font-medium">
                <span className="block text-[10px] sm:text-xs uppercase tracking-widest font-bold opacity-50 mb-1">Deleting User:</span>
                <span className="text-lg sm:text-xl font-black block">{deletingUser?.full_name}</span>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem] shrink-0">
              <Button variant="ghost" onClick={() => setDeletingUser(null)} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 - 动画层 */}
      <div className="space-y-4 sm:space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Users</h1>
            <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage system users, roles, and status.</p>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={openAddModal} className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all">
              <Plus size={16} className="mr-1.5 shrink-0" /> Add User
            </Button>
          </div>
        </header>

        <Card className="p-0 overflow-hidden shadow-xl shadow-orange-500/5 border-2 border-orange-500/20 flex flex-col min-h-0 rounded-[24px]">
          
          {/* Toolbar - 【完美响应式阶梯修复】 */}
          <div className="p-4 sm:p-6 border-b border-orange-500/10 flex flex-col xl:flex-row xl:items-center justify-between gap-4 bg-white shrink-0">
            <div className="relative w-full xl:w-80 shrink-0">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
              <Input 
                placeholder="Search users..." 
                className="pl-11 bg-white border border-orange-500/40 hover:border-orange-500 rounded-xl shadow-sm h-11 w-full focus:ring-2 focus:ring-orange-500/30 font-medium transition-all"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)} 
                autoComplete="off" 
                name="search-query-hidden" 
              />
            </div>
            
            {/* 核心修复点：
                1. 手机端: grid-cols-1
                2. iPad Mini (sm): sm:grid-cols-2 (一行展示2个，不会因为太窄而挤在一起)
                3. iPad Pro (lg): lg:grid-cols-3 (屏幕变宽，一行可以装下3个)
            */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 w-full xl:w-auto xl:flex-1 xl:max-w-3xl xl:justify-end">
              <Select value={filterProvider} onValueChange={(val) => { setFilterProvider(val); setCurrentPage(1); }}>
                <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                  <SelectValue placeholder="All Channels" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Channels (所有渠道)</SelectItem>
                  <SelectItem value="standard">Standard (常规注册)</SelectItem>
                  <SelectItem value="google">Google (谷歌)</SelectItem>
                  <SelectItem value="facebook">Facebook (脸书)</SelectItem>
                </SelectContent>
              </Select>

              <Select value={filterRole} onValueChange={(val) => { setFilterRole(val); setCurrentPage(1); }}>
                <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                  <SelectValue placeholder="All Roles" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Roles (所有角色)</SelectItem>
                  <SelectItem value="0">SuperAdmin</SelectItem>
                  <SelectItem value="1">Admin</SelectItem>
                  <SelectItem value="2">Premium User</SelectItem>
                  <SelectItem value="3">Basic User</SelectItem>
                </SelectContent>
              </Select>

              <Select value={filterStatus} onValueChange={(val) => { setFilterStatus(val); setCurrentPage(1); }}>
                <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                  <SelectValue placeholder="All Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status (所有状态)</SelectItem>
                  <SelectItem value="1">Active</SelectItem>
                  <SelectItem value="0">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Mobile & Tablet Portrait View (Cards) */}
          <div className="lg:hidden flex flex-col p-4 gap-4 bg-orange-50/20 max-h-[60vh] overflow-y-auto custom-scrollbar">
            {isLoading ? (
              <div className="text-center py-8"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></div>
            ) : users.map((u) => (
               <div key={u.id} className="bg-white p-4 rounded-2xl shadow-sm border border-orange-500/10 shadow-black/5 flex flex-col gap-3">
                  <div className="flex justify-between items-start">
                     <div className="flex items-center gap-3">
                        {u.image_path ? (
                          <img src={u.image_path} alt="Avatar" className="w-12 h-12 rounded-xl object-cover border border-orange-500/10" />
                        ) : (
                          <div className="w-12 h-12 rounded-xl bg-orange-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                            {getInitials(u.full_name)}
                          </div>
                        )}
                        <div>
                          <h3 className="font-extrabold text-sunset-dark text-base leading-tight">{u.full_name}</h3>
                          <p className="text-xs font-semibold text-sunset-dark/50">{u.email}</p>
                        </div>
                     </div>
                  </div>
                  
                  <div className="flex flex-wrap gap-1.5 mt-1 border-t border-sunset-primary/5 pt-3">
                     <RoleBadge role={u.role} />
                     <ProviderBadge provider={u.provider} />
                     <StatusBadge status={u.status} />
                  </div>

                  <div className="flex gap-2 pt-2 mt-1">
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-blue-500 hover:bg-blue-50 transition-all border border-transparent" onClick={() => setViewingUser(u)}><Eye size={14} className="mr-1 inline"/> View</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-emerald-500 hover:bg-emerald-50 transition-all border border-transparent" onClick={() => openEditModal(u)}><Edit2 size={14} className="mr-1 inline"/> Edit</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-red-500 hover:bg-red-50 transition-all border border-transparent" onClick={() => setDeletingUser(u)}><Trash2 size={14} className="mr-1 inline"/> Delete</Button>
                  </div>
               </div>
            ))}
            {!isLoading && users.length === 0 && (
               <div className="text-center p-8 font-medium text-sunset-dark/40 bg-white rounded-2xl border border-orange-500/10">No users found matching criteria.</div>
            )}
          </div>

          {/* Desktop & Tablet Landscape View (Table) */}
          <div className="hidden lg:block overflow-x-auto custom-scrollbar">
            <table className="w-full text-left border-collapse min-w-[850px]">
              <thead>
                <tr className="bg-gradient-to-r from-orange-500 to-red-500 text-[10px] sm:text-xs font-black text-white uppercase tracking-widest border-b border-orange-500/20">
                  <th className="p-4 pl-6 whitespace-nowrap w-[22%] min-w-[180px]">Full Name</th>
                  <th className="p-4 whitespace-nowrap w-[25%] min-w-[200px]">Email</th>
                  <th className="p-4 whitespace-nowrap w-[15%] min-w-[120px]">Channel</th>
                  <th className="p-4 whitespace-nowrap w-[15%] min-w-[140px]">Role</th>
                  <th className="p-4 whitespace-nowrap w-[10%] min-w-[100px]">Status</th>
                  <th className="p-4 text-center pr-6 w-[13%] min-w-[130px]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-orange-500/10">
                {isLoading ? (
                  <tr>
                    <td colSpan={6} className="p-12 text-center"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></td>
                  </tr>
                ) : users.map((u) => (
                  <tr key={u.id} className="hover:bg-orange-50/40 transition-colors">
                    <td className="p-4 pl-6 font-bold text-sunset-dark">
                      <div className="flex items-center gap-3">
                        {u.image_path ? (
                          <img src={u.image_path} alt="Avatar" className="w-9 h-9 rounded-lg object-cover border border-orange-500/10" />
                        ) : (
                          <div className="w-9 h-9 rounded-lg bg-orange-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                            {getInitials(u.full_name)}
                          </div>
                        )}
                        <span className="truncate">{u.full_name}</span>
                      </div>
                    </td>
                    <td className="p-4 font-medium text-sunset-dark/70 text-sm truncate max-w-[200px]">{u.email}</td>
                    
                    <td className="p-4"><ProviderBadge provider={u.provider} /></td>
                    <td className="p-4"><RoleBadge role={u.role} /></td>
                    <td className="p-4"><StatusBadge status={u.status} /></td>
                    
                    <td className="p-4 pr-6">
                      <div className="flex items-center justify-center gap-1">
                         <button onClick={() => setViewingUser(u)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-500/10 rounded-xl transition-colors" title="View"><Eye size={18} /></button>
                         <button onClick={() => openEditModal(u)} className="p-2 text-sunset-dark/40 hover:text-emerald-500 hover:bg-emerald-500/10 rounded-xl transition-colors" title="Edit"><Edit2 size={18} /></button>
                         <button onClick={() => setDeletingUser(u)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors" title="Delete"><Trash2 size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!isLoading && users.length === 0 && (
                  <tr>
                    <td colSpan={6} className="p-12 text-center text-sunset-dark/40 font-medium">No users found matching your search.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          
          {totalPages > 0 && (
            <div className="flex items-center justify-between px-6 py-4 border-t border-orange-500/10 overflow-x-auto hide-scroll shrink-0 mt-auto bg-white">
              <div className="hidden sm:block shrink-0">
                <p className="text-sm text-sunset-dark/60 font-medium tracking-tight">
                  Page <span className="font-bold text-sunset-dark">{currentPage}</span> of <span className="font-bold text-sunset-dark">{totalPages}</span>
                </p>
              </div>
              <div className="flex gap-2">
                <button onClick={() => setCurrentPage(Math.max(1, currentPage - 1))} disabled={currentPage === 1} className="relative inline-flex items-center rounded-xl bg-white px-3 py-2 text-sm font-bold text-sunset-dark/60 ring-1 ring-inset ring-orange-500/20 hover:bg-orange-50/10 focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"><ChevronLeft size={16} /></button>
                <div className="flex items-center gap-1">
                  {[...Array(totalPages)].map((_, i) => (
                     <button key={i} onClick={() => setCurrentPage(i + 1)} className={`relative inline-flex items-center justify-center w-9 h-9 rounded-xl text-sm font-bold transition-all ${currentPage === i + 1 ? 'bg-orange-500/10 text-orange-600 ring-1 ring-inset ring-orange-500/30' : 'text-sunset-dark/60 hover:bg-orange-50/10 ring-1 ring-inset ring-orange-500/10'}`}>
                       {i + 1}
                     </button>
                  ))}
                </div>
                <button onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))} disabled={currentPage === totalPages} className="relative inline-flex items-center rounded-xl bg-white px-3 py-2 text-sm font-bold text-sunset-dark/60 ring-1 ring-inset ring-orange-500/20 hover:bg-orange-50/10 focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"><ChevronRight size={16} /></button>
              </div>
            </div>
          )}
        </Card>
      </div>
    </>
  );
}
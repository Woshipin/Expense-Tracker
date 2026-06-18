"use client";

import React, { useState, useEffect } from "react";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Loader2, X, ShieldCheck, CreditCard, Settings } from "lucide-react";
import api from "@/lib/axios";

// ------------------------------------
// UI 组件：状态标签 (全局统一管理颜色)
// ------------------------------------
const StatusBadge = ({ status }: { status: any }) => {
  return String(status) === '1'
    ? <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-green-50 text-green-600">Active</span>
    : <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-red-50 text-red-600">Inactive</span>;
};

// 获取首字母缩写用于生成默认图标 (例如 PayPal -> PP)
const getInitials = (name: string) => { 
  return !name ? "PM" : name.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2); 
};

export default function PaymentMethodsPage() {
  const [methods, setMethods] = useState<any[]>([]);
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingMethod, setViewingMethod] = useState<any>(null);
  const [editingMethod, setEditingMethod] = useState<any>(null);
  const [deletingMethod, setDeletingMethod] = useState<any>(null);
  
  // Search & Filter
  const [searchQuery, setSearchQuery] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Loading States
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Form Fields State
  const [formData, setFormData] = useState({
    name: "", description: "", status: "1" 
  });
  const [errors, setErrors] = useState<any>({});
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchMethods = async () => {
    setIsLoading(true);
    try {
      const params: any = { page: currentPage };
      if (searchQuery) params.search = searchQuery;
      if (filterStatus !== "all") params.status = filterStatus;

      const response = await api.get('/payment-methods', { params });
      setMethods(response.data.data || response.data); 
      setTotalPages(response.data.last_page || 1);
    } catch (error) {
      showToast("Failed to fetch payment methods. Check backend.", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchMethods();
  }, [currentPage, filterStatus]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      setCurrentPage(1);
      fetchMethods();
    }, 500);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery]);

  const openAddModal = () => {
    setErrors({});
    setFormData({ name: "", description: "", status: "1" });
    setIsAddOpen(true);
  };

  const openEditModal = (m: any) => {
    setErrors({});
    setFormData({ name: m.name, description: m.description || "", status: String(m.status) });
    setEditingMethod(m);
  };

  const handleSaveMethod = async () => {
    setIsSaving(true);
    setErrors({});
    
    const data = {
      name: formData.name,
      description: formData.description,
      status: formData.status
    };

    try {
      if (editingMethod) {
        await api.put(`/payment-methods/${editingMethod.id}`, data);
        showToast('Payment method updated successfully!', 'success');
        setEditingMethod(null);
      } else {
        await api.post('/payment-methods', data);
        showToast('Payment method added successfully!', 'success');
        setIsAddOpen(false);
      }
      fetchMethods();
    } catch (error: any) {
      if (error.response && error.response.status === 422) setErrors(error.response.data.errors);
      else showToast(error.response?.data?.error || "Operation failed. Server error 500.", "error");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      await api.delete(`/payment-methods/${deletingMethod.id}`);
      showToast('Payment method deleted successfully', 'success');
      setDeletingMethod(null);
      fetchMethods();
    } catch (error: any) {
      showToast(error.response?.data?.error || "Failed to delete payment method", "error");
      setDeletingMethod(null);
    }
  };

  return (
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. View Payment Method Modal */}
      {viewingMethod && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-4xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">Payment Method Details</h2>
              <button onClick={() => setViewingMethod(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 sm:gap-6 items-stretch">
                <div className="bg-blue-50/40 rounded-2xl sm:rounded-[1.5rem] p-6 border border-blue-100 flex flex-col items-center justify-center gap-4 text-center h-full relative overflow-hidden">
                  <div className="absolute top-0 w-full h-24 bg-gradient-to-b from-blue-100/50 to-transparent"></div>
                  <div className="relative z-10 shrink-0">
                    <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-[2rem] bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white flex items-center justify-center font-bold text-4xl border-[3px] border-white shadow-lg uppercase">
                      {getInitials(viewingMethod?.name)}
                    </div>
                  </div>
                  <div className="relative z-10 mt-2">
                    <h3 className="font-extrabold text-sunset-dark text-xl sm:text-2xl leading-tight">{viewingMethod?.name}</h3>
                    <p className="font-medium text-sunset-dark/60 text-sm mt-2 px-4">{viewingMethod?.description || 'No description provided.'}</p>
                  </div>
                </div>
                <div className="bg-emerald-50/40 rounded-2xl sm:rounded-[1.5rem] p-6 border border-emerald-100 flex flex-col justify-center h-full">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center mb-5 sm:mb-6">
                    <ShieldCheck size={18} className="mr-2 text-emerald-500" /> System Info
                  </h3>
                  <div className="space-y-4 sm:space-y-6">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Payment Channel</label>
                      <div className="font-semibold text-sunset-dark/85 text-sm">{viewingMethod?.name}</div>
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Description</label>
                      <div className="font-semibold text-sunset-dark/85 text-sm">{viewingMethod?.description || '-'}</div>
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Current Status</label>
                      <StatusBadge status={viewingMethod?.status} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex justify-end shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button onClick={() => setViewingMethod(null)} className="w-full sm:w-auto px-6 sm:px-8 shadow-sm">Close Window</Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit Payment Method Modal */}
      {(isAddOpen || editingMethod) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-[950px] rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingMethod ? "Edit Payment Method" : "Add Payment Method"}</h2>
              <button onClick={() => { setIsAddOpen(false); setEditingMethod(null); }} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-4 sm:p-6 md:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 sm:gap-6 items-start">
                <div className="bg-blue-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-blue-100 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <CreditCard size={16} className="mr-2 text-blue-500" /> Channel Information
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Method Name (e.g. PayPal, Bank Transfer)</label>
                    <Input placeholder="e.g. PayPal" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" autoComplete="off" />
                    {errors.name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.name[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Description</label>
                    <textarea placeholder="Enter description or instructions..." value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} className="w-full rounded-xl border border-orange-500/40 focus:border-orange-500 p-3 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-orange-500/30 transition-all custom-scrollbar min-h-[100px]" />
                    {errors.description && <p className="text-xs text-red-500 mt-1 pl-1">{errors.description[0]}</p>}
                  </div>
                </div>
                <div className="bg-emerald-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-emerald-100 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <Settings size={16} className="mr-2 text-emerald-500" /> Configuration
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Status</label>
                    <Select value={formData.status} onValueChange={(val) => setFormData({...formData, status: val})}>
                      <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                        <SelectValue placeholder="Select Status" />
                      </SelectTrigger>
                      <SelectContent className="z-[10050]">
                        <SelectItem value="1">Active (正常使用)</SelectItem>
                        <SelectItem value="0">Inactive (停用隐藏)</SelectItem>
                      </SelectContent>
                    </Select>
                    {errors.status && <p className="text-xs text-red-500 mt-1 pl-1">{errors.status[0]}</p>}
                  </div>
                </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-10 sm:h-11 text-xs sm:text-sm" onClick={() => { setIsAddOpen(false); setEditingMethod(null); }}>Cancel</Button>
              <Button onClick={handleSaveMethod} disabled={isSaving} className="flex-1 sm:flex-none px-6 sm:px-8 h-10 sm:h-11 text-xs sm:text-sm flex items-center justify-center shadow-md">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Method"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingMethod && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg sm:text-xl font-bold text-red-600">Delete Payment Method</h2>
              <button onClick={() => setDeletingMethod(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 sm:p-8 flex-1 overflow-y-auto">
              <p className="font-medium text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this payment method? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl sm:rounded-[1.5rem] border border-red-100 font-medium">
                <span className="block text-[10px] sm:text-xs uppercase tracking-widest font-bold opacity-50 mb-1">Deleting Method:</span>
                <span className="text-lg sm:text-xl font-black block">{deletingMethod?.name}</span>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem] shrink-0">
              <Button variant="ghost" onClick={() => setDeletingMethod(null)} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 - 动画层 */}
      <div className="space-y-4 sm:space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Payment Methods</h1>
            <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage system payment channels and their availability.</p>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={openAddModal} className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all">
              <Plus size={16} className="mr-1.5 shrink-0" /> Add Method
            </Button>
          </div>
        </header>

        <Card className="p-0 overflow-hidden shadow-xl shadow-orange-500/5 border-2 border-orange-500/20 flex flex-col min-h-0 rounded-[24px]">
          
          {/* Toolbar (修复了平板端的挤压问题) */}
          <div className="p-4 sm:p-6 border-b border-orange-500/10 flex flex-col md:flex-row items-center justify-between gap-4 bg-white shrink-0">
            <div className="relative w-full md:flex-1 md:max-w-md shrink-0">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
              <Input 
                placeholder="Search payment methods..." 
                className="pl-11 bg-white border border-orange-500/40 hover:border-orange-500 rounded-xl shadow-sm h-11 w-full focus:ring-2 focus:ring-orange-500/30 font-medium transition-all"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)} 
                autoComplete="off" 
              />
            </div>
            
            <div className="w-full md:w-48 shrink-0">
              <Select value={filterStatus} onValueChange={(val) => { setFilterStatus(val); setCurrentPage(1); }}>
                <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30 w-full">
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

          {/* Mobile & Tablet Portrait View (Cards) - 将断点从 md:hidden 改为 lg:hidden，完美适配 iPad 竖屏 */}
          <div className="lg:hidden flex flex-col p-4 gap-4 bg-orange-50/20 max-h-[60vh] overflow-y-auto custom-scrollbar">
            {isLoading ? (
              <div className="text-center py-8"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></div>
            ) : methods.map((m) => (
               <div key={m.id} className="bg-white p-4 rounded-2xl shadow-sm border border-orange-500/10 shadow-black/5 flex flex-col gap-3">
                  <div className="flex justify-between items-start">
                     <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-orange-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                          {getInitials(m.name)}
                        </div>
                        <div>
                          <h3 className="font-extrabold text-sunset-dark text-base leading-tight">{m.name}</h3>
                          <p className="text-xs font-semibold text-sunset-dark/50 line-clamp-1 mt-0.5">{m.description || 'No description'}</p>
                        </div>
                     </div>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-1 border-t border-sunset-primary/5 pt-3">
                     <StatusBadge status={m.status} />
                  </div>
                  <div className="flex gap-2 pt-2 mt-1">
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-blue-500 hover:bg-blue-50 transition-all border border-transparent" onClick={() => setViewingMethod(m)}><Eye size={14} className="mr-1 inline"/> View</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-emerald-500 hover:bg-emerald-50 transition-all border border-transparent" onClick={() => openEditModal(m)}><Edit2 size={14} className="mr-1 inline"/> Edit</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-red-500 hover:bg-red-50 transition-all border border-transparent" onClick={() => setDeletingMethod(m)}><Trash2 size={14} className="mr-1 inline"/> Delete</Button>
                  </div>
               </div>
            ))}
            {!isLoading && methods.length === 0 && (
               <div className="text-center p-8 font-medium text-sunset-dark/40 bg-white rounded-2xl border border-orange-500/10">No payment methods found.</div>
            )}
          </div>

          {/* Desktop & Tablet Landscape View (Table) - 将断点从 hidden md:block 改为 hidden lg:block */}
          <div className="hidden lg:block overflow-x-auto custom-scrollbar">
            {/* 优化了表格列宽，使用 min-w 防止极端情况下的挤压 */}
            <table className="w-full text-left border-collapse min-w-[700px]">
              <thead>
                <tr className="bg-gradient-to-r from-orange-500 to-red-500 text-[10px] sm:text-xs font-black text-white uppercase tracking-widest border-b border-orange-500/20">
                  <th className="p-4 pl-6 whitespace-nowrap w-[25%] min-w-[150px]">Method Name</th>
                  <th className="p-4 whitespace-nowrap w-[45%] min-w-[200px]">Description</th>
                  <th className="p-4 whitespace-nowrap w-[15%] min-w-[100px]">Status</th>
                  <th className="p-4 text-center pr-6 w-[15%] min-w-[120px]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-orange-500/10">
                {isLoading ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></td>
                  </tr>
                ) : methods.map((m) => (
                  <tr key={m.id} className="hover:bg-orange-50/40 transition-colors">
                    <td className="p-4 pl-6 font-bold text-sunset-dark">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-orange-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                          {getInitials(m.name)}
                        </div>
                        <span className="truncate">{m.name}</span>
                      </div>
                    </td>
                    <td className="p-4 font-medium text-sunset-dark/70 text-sm truncate max-w-[300px]">
                      {m.description || <span className="text-gray-400 italic">N/A</span>}
                    </td>
                    <td className="p-4"><StatusBadge status={m.status} /></td>
                    <td className="p-4 pr-6">
                      <div className="flex items-center justify-center gap-1">
                         <button onClick={() => setViewingMethod(m)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-500/10 rounded-xl transition-colors" title="View"><Eye size={18} /></button>
                         <button onClick={() => openEditModal(m)} className="p-2 text-sunset-dark/40 hover:text-emerald-500 hover:bg-emerald-500/10 rounded-xl transition-colors" title="Edit"><Edit2 size={18} /></button>
                         <button onClick={() => setDeletingMethod(m)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors" title="Delete"><Trash2 size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!isLoading && methods.length === 0 && (
                  <tr>
                    <td colSpan={4} className="p-12 text-center text-sunset-dark/40 font-medium">No payment methods found matching your search.</td>
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
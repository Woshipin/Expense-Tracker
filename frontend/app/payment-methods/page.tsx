"use client";

import React, { useState, useEffect, useMemo } from "react";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Loader2, X } from "lucide-react";
import * as Icons from "lucide-react"; 
import api from "@/lib/axios";

// 预设的可选支付方式 Lucide 图标
const AVAILABLE_ICONS = [
  "CreditCard", "Wallet", "Banknote", "Landmark", "QrCode", "DollarSign", "Coins", "Smartphone"
];

// 预设的可选精美颜色
const AVAILABLE_COLORS = [
  "#3b82f6", "#10b981", "#22c55e", "#14b8a6", "#06b6d4", "#0ea5e9", "#4f46e5", "#6366f1", 
  "#8b5cf6", "#a855f7", "#d946ef", "#ec4899", "#f43f5e", "#ef4444", "#f97316", "#f59e0b", 
  "#eab308", "#64748b"
];

const DynamicIcon = ({ name, className, style }: { name: string; className?: string; style?: React.CSSProperties }) => {
  const IconComponent = (Icons as any)[name] || Icons.HelpCircle;
  return <IconComponent className={className} style={style} size={20} />;
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
    name: "", 
    type_id: "1", 
    icon: "CreditCard", 
    color: "#3b82f6", 
    description: "", 
    status: "1" 
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
      showToast("Failed to fetch payment methods.", "error");
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
    setFormData({ name: "", type_id: "1", icon: "CreditCard", color: "#3b82f6", description: "", status: "1" });
    setIsAddOpen(true);
  };

  const openEditModal = (m: any) => {
    setErrors({});
    setFormData({ 
      name: m.name, 
      type_id: String(m.type_id), 
      icon: m.icon || "CreditCard", 
      color: m.color || "#3b82f6", 
      description: m.description || "", 
      status: String(m.status) 
    });
    setEditingMethod(m);
  };

  const handleSaveMethod = async () => {
    setIsSaving(true);
    setErrors({});
    
    try {
      if (editingMethod) {
        await api.put(`/payment-methods/${editingMethod.id}`, formData);
        showToast('Payment method updated successfully!', 'success');
        setEditingMethod(null);
      } else {
        await api.post('/payment-methods', formData);
        showToast('Payment method added successfully!', 'success');
        setIsAddOpen(false);
      }
      fetchMethods();
    } catch (error: any) {
      if (error.response && error.response.status === 422) {
        setErrors(error.response.data.errors);
      } else {
        showToast(error.response?.data?.message || error.response?.data?.error || "Operation failed.", "error");
      }
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
      showToast(error.response?.data?.message || error.response?.data?.error || "Failed to delete payment method", "error");
      setDeletingMethod(null);
    }
  };

  const groupedMethods = useMemo(() => {
    const income = methods.filter(m => String(m.type_id) === '2');
    const expense = methods.filter(m => String(m.type_id) === '1');
    return { income, expense };
  }, [methods]);

  return (
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. View Payment Method Modal */}
      {viewingMethod && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl flex flex-col overflow-hidden">
            <div className="px-6 py-5 border-b border-sunset-primary/10 flex justify-between items-center bg-gray-50/50">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">Method Details</h2>
              <button onClick={() => setViewingMethod(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6 flex flex-col items-center text-center gap-4">
              <div 
                className="w-20 h-24 rounded-2xl flex items-center justify-center shadow-md animate-bounce"
                style={{ backgroundColor: `${viewingMethod?.color}15`, color: viewingMethod?.color }}
              >
                <DynamicIcon name={viewingMethod?.icon || "CreditCard"} className="w-10 h-10" />
              </div>
              <div>
                <h3 className="text-xl font-extrabold text-sunset-dark">{viewingMethod?.name}</h3>
                <span className="inline-flex mt-1.5 py-1 px-2.5 rounded-lg text-xs font-bold uppercase tracking-wider bg-orange-50 text-orange-600">
                  {String(viewingMethod?.type_id) === '2' ? 'Income' : 'Expense'}
                </span>
              </div>
              <p className="text-sm font-semibold text-sunset-dark/60 mt-2 px-4 bg-slate-50 py-3 rounded-xl w-full border border-gray-100">
                {viewingMethod?.description || 'No description provided.'}
              </p>
            </div>
            <div className="px-6 py-5 border-t border-sunset-primary/10 flex justify-end bg-gray-50/50">
              <Button onClick={() => setViewingMethod(null)} className="w-full shadow-sm bg-sunset-dark text-white hover:bg-black">Close</Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit Payment Method Modal */}
      {(isAddOpen || editingMethod) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-xl rounded-3xl shadow-2xl flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-6 py-5 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingMethod ? "Edit Payment Method" : "Add Payment Method"}</h2>
              <button onClick={() => { setIsAddOpen(false); setEditingMethod(null); }} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar flex-1 space-y-5">
              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Method Name</label>
                <Input 
                  placeholder="E.g. PayPal, Bank Transfer" 
                  value={formData.name} 
                  onChange={(e) => setFormData({...formData, name: e.target.value})} 
                  className="h-10 sm:h-11 text-sm bg-white" 
                  autoComplete="off" 
                />
                {errors.name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.name[0]}</p>}
              </div>

              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Type</label>
                <Select value={formData.type_id} onValueChange={(val) => setFormData({...formData, type_id: val})}>
                  <SelectTrigger className="bg-white rounded-xl h-11 text-sm font-medium border-orange-500/40 text-sunset-dark shadow-sm">
                    <SelectValue placeholder="Select type" />
                  </SelectTrigger>
                  <SelectContent className="z-[10050]">
                    <SelectItem value="1">Expense</SelectItem>
                    <SelectItem value="2">Income</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-2.5 block">Select icon</label>
                <div className="grid grid-cols-4 sm:grid-cols-8 gap-2 p-3 bg-slate-50 rounded-2xl border border-gray-100">
                  {AVAILABLE_ICONS.map((iconName) => {
                    const isSelected = formData.icon === iconName;
                    return (
                      <button
                        key={iconName}
                        type="button"
                        onClick={() => setFormData({...formData, icon: iconName})}
                        className={`h-11 w-11 rounded-xl flex items-center justify-center transition-all ${
                          isSelected 
                            ? 'bg-orange-500 text-white shadow-md scale-105' 
                            : 'bg-white hover:bg-orange-50 text-sunset-dark border border-gray-100'
                        }`}
                      >
                        <DynamicIcon name={iconName} />
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-2.5 block">Select color</label>
                <div className="flex flex-wrap gap-3 p-3 bg-slate-50 rounded-2xl border border-gray-100">
                  {AVAILABLE_COLORS.map((colorHex) => {
                    const isSelected = formData.color === colorHex;
                    return (
                      <button
                        key={colorHex}
                        type="button"
                        onClick={() => setFormData({...formData, color: colorHex})}
                        className={`h-9 w-9 rounded-full transition-all border-2 flex items-center justify-center ${
                          isSelected ? 'border-orange-500 scale-110 shadow-md' : 'border-transparent hover:scale-105'
                        }`}
                        style={{ backgroundColor: colorHex }}
                      >
                        {isSelected && <div className="w-2.5 h-2.5 rounded-full bg-white" />}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Description</label>
                  <Input 
                    placeholder="Brief description..." 
                    value={formData.description} 
                    onChange={(e) => setFormData({...formData, description: e.target.value})} 
                    className="h-11 text-sm bg-white" 
                  />
                </div>
                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Status</label>
                  <Select value={formData.status} onValueChange={(val) => setFormData({...formData, status: val})}>
                    <SelectTrigger className="bg-white rounded-xl h-11 text-sm font-medium border-orange-500/40 text-sunset-dark shadow-sm">
                      <SelectValue placeholder="Select Status" />
                    </SelectTrigger>
                    <SelectContent className="z-[10050]">
                      <SelectItem value="1">Active</SelectItem>
                      <SelectItem value="0">Inactive</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

            </div>

            <div className="px-6 py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-11 text-sm bg-white border" onClick={() => { setIsAddOpen(false); setEditingMethod(null); }}>Cancel</Button>
              <Button onClick={handleSaveMethod} disabled={isSaving} className="flex-1 sm:flex-none px-8 h-11 text-sm flex items-center justify-center shadow-md bg-orange-500 text-white hover:bg-orange-600">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Method"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingMethod && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl flex flex-col overflow-hidden">
            <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg font-black text-red-600">Delete Method</h2>
              <button onClick={() => setDeletingMethod(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6">
              <p className="font-semibold text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this payment method? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-bold flex items-center gap-3">
                 <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
                   <DynamicIcon name={deletingMethod?.icon || "CreditCard"} />
                 </div>
                 <div>
                   <span className="block text-[10px] uppercase tracking-widest font-black opacity-50">Deleting Method</span>
                   <span className="text-lg font-black block mt-0.5">{deletingMethod?.name}</span>
                 </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 shrink-0">
              <Button variant="ghost" onClick={() => setDeletingMethod(null)} className="flex-1 sm:flex-none text-sm h-11 border bg-white shadow-sm">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-sm h-11 shadow-md">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 */}
      <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Payment Methods</h1>
            <p className="text-sm font-semibold text-sunset-dark/60 mt-1">Manage system payment channels and their availability.</p>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={openAddModal} className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all bg-orange-500 text-white hover:bg-orange-600">
              <Plus size={16} className="mr-1.5 shrink-0" /> Add Method
            </Button>
          </div>
        </header>

        {/* Toolbar */}
        <div className="flex flex-col md:flex-row items-center gap-4 bg-white p-4 rounded-3xl border border-orange-500/10 shadow-sm">
          <div className="relative w-full md:flex-1 shrink-0">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
            <Input 
              placeholder="Search payment methods..." 
              className="pl-11 bg-white border border-orange-500/30 hover:border-orange-500 rounded-2xl shadow-sm h-11 w-full focus:ring-2 focus:ring-orange-500/30 font-medium transition-all"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)} 
              autoComplete="off" 
            />
          </div>
          
          <div className="w-full md:w-56 shrink-0">
            <Select value={filterStatus} onValueChange={(val) => { setFilterStatus(val); setCurrentPage(1); }}>
              <SelectTrigger className="bg-white border-orange-500/30 hover:border-orange-500 rounded-2xl h-11 text-xs font-extrabold text-sunset-dark shadow-sm">
                <SelectValue placeholder="All Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="1">Active</SelectItem>
                <SelectItem value="0">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* 栅格列表 */}
        {isLoading ? (
          <div className="text-center py-20 bg-white rounded-[24px] border"><Loader2 className="animate-spin text-orange-500 mx-auto w-10 h-10" /></div>
        ) : (
          <div className="space-y-8">
            
            {/* 1. INCOME GROUP */}
            <div className="space-y-4">
              {/* 【修复】：移除大写类名，只保留首字母大写 */}
              <h2 className="text-lg font-black text-emerald-600 flex items-center gap-2 border-b border-gray-100 pb-2">
                Income <span className="text-xs bg-emerald-50 px-2 py-0.5 rounded-full font-bold text-emerald-600">({groupedMethods.income.length})</span>
              </h2>
              <div className="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-4">
                {groupedMethods.income.map((m) => (
                  <div key={m.id} className="bg-white p-4 rounded-3xl border border-gray-100 shadow-sm hover:border-orange-500/30 hover:shadow-md transition-all flex items-center justify-between group gap-2">
                    <div className="flex items-center gap-4 min-w-0 flex-1">
                      <div 
                        className="w-12 h-14 rounded-2xl flex items-center justify-center shrink-0 shadow-sm"
                        style={{ backgroundColor: `${m.color || '#3b82f6'}15`, color: m.color || '#3b82f6' }}
                      >
                        <DynamicIcon name={m.icon || "CreditCard"} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h3 className="font-extrabold text-sunset-dark text-base truncate">{m.name}</h3>
                        <p className="text-xs font-semibold text-sunset-dark/40 truncate mt-0.5">{m.description || 'No description'}</p>
                      </div>
                    </div>
                    <div className="flex gap-1 bg-slate-50 p-1.5 rounded-2xl border border-gray-100 shrink-0">
                      <button onClick={() => setViewingMethod(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-blue-500 hover:bg-blue-50 transition-colors"><Eye size={16}/></button>
                      <button onClick={() => openEditModal(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-emerald-500 hover:bg-emerald-50 transition-colors"><Edit2 size={16}/></button>
                      <button onClick={() => setDeletingMethod(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-red-500 hover:bg-red-50 transition-colors"><Trash2 size={16}/></button>
                    </div>
                  </div>
                ))}
                {groupedMethods.income.length === 0 && (
                  <div className="col-span-full text-center py-8 font-semibold text-gray-400 bg-slate-50/50 rounded-2xl border border-dashed">No incoming channels.</div>
                )}
              </div>
            </div>

            {/* 2. OUTGOING GROUP */}
            <div className="space-y-4">
              {/* 【修复】：支出栏标题已完美更改为 Expense，无大写类名，实现完美的 Title Case */}
              <h2 className="text-lg font-black text-red-500 flex items-center gap-2 border-b border-gray-100 pb-2">
                Expense <span className="text-xs bg-red-50 px-2 py-0.5 rounded-full font-bold text-red-500">({groupedMethods.expense.length})</span>
              </h2>
              <div className="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-4">
                {groupedMethods.expense.map((m) => (
                  <div key={m.id} className="bg-white p-4 rounded-3xl border border-gray-100 shadow-sm hover:border-orange-500/30 hover:shadow-md transition-all flex items-center justify-between group gap-2">
                    <div className="flex items-center gap-4 min-w-0 flex-1">
                      <div 
                        className="w-12 h-14 rounded-2xl flex items-center justify-center shrink-0 shadow-sm"
                        style={{ backgroundColor: `${m.color || '#3b82f6'}15`, color: m.color || '#3b82f6' }}
                      >
                        <DynamicIcon name={m.icon || "CreditCard"} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h3 className="font-extrabold text-sunset-dark text-base truncate">{m.name}</h3>
                        <p className="text-xs font-semibold text-sunset-dark/40 truncate mt-0.5">{m.description || 'No description'}</p>
                      </div>
                    </div>
                    <div className="flex gap-1 bg-slate-50 p-1.5 rounded-2xl border border-gray-100 shrink-0">
                      <button onClick={() => setViewingMethod(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-blue-500 hover:bg-blue-50 transition-colors"><Eye size={16}/></button>
                      <button onClick={() => openEditModal(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-emerald-500 hover:bg-emerald-50 transition-colors"><Edit2 size={16}/></button>
                      <button onClick={() => setDeletingMethod(m)} className="p-1.5 rounded-lg text-sunset-dark/50 hover:text-red-500 hover:bg-red-50 transition-colors"><Trash2 size={16}/></button>
                    </div>
                  </div>
                ))}
                {groupedMethods.expense.length === 0 && (
                  <div className="col-span-full text-center py-8 font-semibold text-gray-400 bg-slate-50/50 rounded-2xl border border-dashed">No outgoing channels.</div>
                )}
              </div>
            </div>

          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-orange-500/10 overflow-x-auto hide-scroll shrink-0 mt-auto bg-white">
            <div className="hidden sm:block shrink-0">
              <p className="text-sm text-sunset-dark/60 font-medium tracking-tight">
                Page <span className="font-bold text-sunset-dark">{currentPage}</span> of <span className="font-bold text-sunset-dark">{totalPages}</span>
              </p>
            </div>
            <div className="flex gap-2">
              <button onClick={() => setCurrentPage(Math.max(1, currentPage - 1))} disabled={currentPage === 1} className="p-2 rounded-xl bg-white border hover:bg-orange-50 disabled:opacity-50 transition-colors"><ChevronLeft size={16} /></button>
              <div className="flex items-center gap-1">
                {[...Array(totalPages)].map((_, i) => (
                   <button key={i} onClick={() => setCurrentPage(i + 1)} className={`relative inline-flex items-center justify-center w-9 h-9 rounded-xl text-sm font-bold transition-all ${currentPage === i + 1 ? 'bg-orange-500/10 text-orange-600 border border-orange-500/30' : 'text-sunset-dark/60 hover:bg-orange-50/10 border'}`}>
                     {i + 1}
                   </button>
                ))}
              </div>
              <button onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))} disabled={currentPage === totalPages} className="p-2 rounded-xl bg-white border hover:bg-orange-50 disabled:opacity-50 transition-colors"><ChevronRight size={16} /></button>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
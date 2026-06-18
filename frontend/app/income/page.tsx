"use client";

import React, { useState, useEffect } from "react";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Loader2, X, Wallet, Clock, RefreshCw, FilterX } from "lucide-react";
import api from "@/lib/axios";

// ------------------------------------
// 获取首字母缩写用于生成默认图标
// ------------------------------------
const getInitials = (name: string) => { 
  return !name ? "IN" : name.split(" ").map(n => n[0]).join("").toUpperCase().substring(0, 2); 
};

// ------------------------------------
// 价格格式化辅助函数：自动删除无意义的 .00
// ------------------------------------
const formatPrice = (price: any) => {
  const num = parseFloat(price);
  if (isNaN(num)) return "0";
  return num % 1 === 0 ? num.toString() : num.toFixed(2);
};

export default function IncomePage() {
  const [incomes, setIncomes] = useState<any[]>([]);
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // 动态选项
  const [categoryOptions, setCategoryOptions] = useState<any[]>([]);
  const [methodOptions, setMethodOptions] = useState<any[]>([]);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingIncome, setViewingIncome] = useState<any>(null);
  const [editingIncome, setEditingIncome] = useState<any>(null);
  const [deletingIncome, setDeletingIncome] = useState<any>(null);
  
  // Search & Filter
  const [searchQuery, setSearchQuery] = useState("");
  const [filterStartDate, setFilterStartDate] = useState("");
  const [filterEndDate, setFilterEndDate] = useState("");
  const [filterCategoryId, setFilterCategoryId] = useState("all");
  const [filterMethodId, setFilterMethodId] = useState("all");

  // Loading States
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Form Fields State
  const [formData, setFormData] = useState({
    title: "", description: "", price: "", date: "", time: "", payment_method_id: "", category_id: "" 
  });
  const [errors, setErrors] = useState<any>({});
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchOptions = async () => {
    try {
      const [catsRes, methodsRes] = await Promise.all([
        api.get('/categories?status=1'), 
        api.get('/payment-methods?status=1')
      ]);
      setCategoryOptions(catsRes.data.data || catsRes.data || []);
      setMethodOptions(methodsRes.data.data || methodsRes.data || []);
    } catch (e) {
      console.error("Failed to load options");
    }
  };

  const fetchIncomes = async () => {
    setIsLoading(true);
    try {
      const params: any = { page: currentPage };
      if (searchQuery) params.search = searchQuery;
      if (filterCategoryId !== "all") params.category_id = filterCategoryId;
      if (filterMethodId !== "all") params.payment_method_id = filterMethodId;
      if (filterStartDate) params.start_date = filterStartDate;
      if (filterEndDate) params.end_date = filterEndDate;

      const response = await api.get('/incomes', { params });
      setIncomes(response.data.data || response.data); 
      setTotalPages(response.data.last_page || 1);
    } catch (error) {
      showToast("Failed to fetch incomes. Check backend.", "error");
    } finally {
      setIsLoading(false);
    }
  };

  // 清空所有过滤器
  const handleClearFilters = () => {
    setSearchQuery("");
    setFilterStartDate("");
    setFilterEndDate("");
    setFilterCategoryId("all");
    setFilterMethodId("all");
    setCurrentPage(1);
    showToast('Filters cleared', 'success');
  };

  useEffect(() => {
    fetchOptions();
  }, []);

  useEffect(() => {
    fetchIncomes();
  }, [currentPage, filterCategoryId, filterMethodId, filterStartDate, filterEndDate]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      setCurrentPage(1);
      fetchIncomes();
    }, 500);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery]);

  const openAddModal = () => {
    setErrors({});
    const now = new Date();
    const defaultDate = now.toISOString().split('T')[0];
    const defaultTime = now.toTimeString().split(' ')[0].substring(0, 5);
    
    setFormData({ 
      title: "", description: "", price: "", 
      date: defaultDate, time: defaultTime, 
      payment_method_id: methodOptions.length > 0 ? String(methodOptions[0].id) : "", 
      category_id: categoryOptions.length > 0 ? String(categoryOptions[0].id) : "" 
    });
    setIsAddOpen(true);
  };

  const openEditModal = (e: any) => {
    setErrors({});
    setFormData({ 
      title: e.title, description: e.description || "", price: String(e.price), 
      date: e.date, time: e.time.substring(0, 5), 
      payment_method_id: String(e.payment_method_id), 
      category_id: String(e.category_id) 
    });
    setEditingIncome(e); // 【修复】：已修正为 setEditingIncome(e)
  };

  const handleSaveIncome = async () => {
    setIsSaving(true);
    setErrors({});
    try {
      if (editingIncome) {
        await api.put(`/incomes/${editingIncome.id}`, formData);
        showToast('Income updated successfully!', 'success');
        setEditingIncome(null);
      } else {
        await api.post('/incomes', formData);
        showToast('Income added successfully!', 'success');
        setIsAddOpen(false);
      }
      fetchIncomes();
    } catch (error: any) {
      if (error.response && error.response.status === 422) setErrors(error.response.data.errors);
      else showToast(error.response?.data?.error || "Operation failed.", "error");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      await api.delete(`/incomes/${deletingIncome.id}`);
      showToast('Income deleted successfully', 'success');
      setDeletingIncome(null);
      fetchIncomes();
    } catch (error: any) {
      showToast(error.response?.data?.error || "Failed to delete income", "error");
      setDeletingIncome(null);
    }
  };

  return (
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. View Income Modal */}
      {viewingIncome && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-4xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">Income Details</h2>
              <button onClick={() => setViewingIncome(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 sm:gap-6 items-stretch">
                
                {/* Left Card: Main Info */}
                <div className="bg-orange-50/40 rounded-2xl sm:rounded-[1.5rem] p-6 border border-orange-100 flex flex-col items-center justify-center gap-4 text-center h-full relative overflow-hidden">
                  <div className="absolute top-0 w-full h-24 bg-gradient-to-b from-orange-100/50 to-transparent"></div>
                  <div className="relative z-10 shrink-0">
                    <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-[2rem] bg-gradient-to-br from-orange-500 to-red-500 text-white flex items-center justify-center font-bold text-3xl border-[3px] border-white shadow-lg">
                      RM
                    </div>
                  </div>
                  <div className="relative z-10 mt-2">
                    <h3 className="font-extrabold text-sunset-dark text-xl sm:text-2xl leading-tight">{viewingIncome?.title}</h3>
                    <p className="font-medium text-sunset-dark/60 text-sm mt-2 px-4">{viewingIncome?.description || 'No description provided.'}</p>
                    <div className="mt-4 inline-flex py-1.5 px-4 rounded-xl text-sm font-bold bg-white text-orange-600 border border-orange-200 shadow-sm">
                      {viewingIncome?.category?.name || 'Unknown Category'}
                    </div>
                  </div>
                </div>

                {/* Right Card: Transaction Info */}
                <div className="bg-slate-50 rounded-2xl sm:rounded-[1.5rem] p-6 border border-slate-100 flex flex-col justify-center h-full">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center mb-5 sm:mb-6">
                    <Wallet size={18} className="mr-2 text-slate-500" /> Transaction Info
                  </h3>
                  <div className="space-y-4 sm:space-y-6">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Amount</label>
                      <div className="font-black text-3xl text-emerald-600">RM {formatPrice(viewingIncome?.price)}</div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Date</label>
                        <div className="font-semibold text-sunset-dark/85 text-sm">{viewingIncome?.date}</div>
                      </div>
                      <div>
                        <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Time</label>
                        <div className="font-semibold text-sunset-dark/85 text-sm">{viewingIncome?.time}</div>
                      </div>
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest block mb-1.5">Payment Method</label>
                      <span className="inline-flex py-1 px-3 rounded-lg text-xs font-bold bg-slate-200 text-slate-700">
                        {viewingIncome?.payment_method?.name || 'Unknown Method'}
                      </span>
                    </div>
                  </div>
                </div>

              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex justify-end shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button onClick={() => setViewingIncome(null)} className="w-full sm:w-auto px-6 sm:px-8 shadow-sm">Close Window</Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit Income Modal */}
      {(isAddOpen || editingIncome) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-[950px] rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingIncome ? "Edit Income" : "Add Income"}</h2>
              <button onClick={() => { setIsAddOpen(false); setEditingIncome(null); }} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-4 sm:p-6 md:p-8 overflow-y-auto custom-scrollbar flex-1">
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 sm:gap-6 items-start">
                
                {/* Left Column */}
                <div className="bg-orange-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-orange-100 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <Wallet size={16} className="mr-2 text-orange-500" /> Basic Details
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Title</label>
                    <Input placeholder="E.g. Salary, Freelance" value={formData.title} onChange={(e) => setFormData({...formData, title: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" autoComplete="off" />
                    {errors.title && <p className="text-xs text-red-500 mt-1 pl-1">{errors.title[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Amount (RM)</label>
                    <Input type="number" step="0.01" placeholder="0.00" value={formData.price} onChange={(e) => setFormData({...formData, price: e.target.value})} className="h-10 sm:h-11 text-sm bg-white font-bold" autoComplete="off" />
                    {errors.price && <p className="text-xs text-red-500 mt-1 pl-1">{errors.price[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Description (Optional)</label>
                    <textarea placeholder="Enter a brief description..." value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} className="w-full rounded-xl border border-orange-500/40 focus:border-orange-500 p-3 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-orange-500/30 transition-all custom-scrollbar min-h-[80px]" />
                    {errors.description && <p className="text-xs text-red-500 mt-1 pl-1">{errors.description[0]}</p>}
                  </div>
                </div>

                {/* Right Column */}
                <div className="bg-slate-50/80 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-slate-200 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <Clock size={16} className="mr-2 text-slate-500" /> Categorization & Time
                  </h3>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Date</label>
                      <Input type="date" value={formData.date} onChange={(e) => setFormData({...formData, date: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" />
                      {errors.date && <p className="text-xs text-red-500 mt-1 pl-1">{errors.date[0]}</p>}
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Time</label>
                      <Input type="time" value={formData.time} onChange={(e) => setFormData({...formData, time: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" />
                      {errors.time && <p className="text-xs text-red-500 mt-1 pl-1">{errors.time[0]}</p>}
                    </div>
                  </div>

                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Category</label>
                    <Select value={formData.category_id} onValueChange={(val) => setFormData({...formData, category_id: val})}>
                      <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                        <SelectValue placeholder="Select Category" />
                      </SelectTrigger>
                      <SelectContent className="z-[10050]">
                        {categoryOptions.length > 0 ? (
                          categoryOptions.map(c => <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>)
                        ) : (
                          <div className="p-2 text-xs text-gray-500">Please add categories first</div>
                        )}
                      </SelectContent>
                    </Select>
                    {errors.category_id && <p className="text-xs text-red-500 mt-1 pl-1">{errors.category_id[0]}</p>}
                  </div>

                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Payment Method</label>
                    <Select value={formData.payment_method_id} onValueChange={(val) => setFormData({...formData, payment_method_id: val})}>
                      <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                        <SelectValue placeholder="Select Method" />
                      </SelectTrigger>
                      <SelectContent className="z-[10050]">
                        {methodOptions.length > 0 ? (
                          methodOptions.map(m => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)
                        ) : (
                          <div className="p-2 text-xs text-gray-500">Please add payment methods first</div>
                        )}
                      </SelectContent>
                    </Select>
                    {errors.payment_method_id && <p className="text-xs text-red-500 mt-1 pl-1">{errors.payment_method_id[0]}</p>}
                  </div>

                </div>

              </div>
            </div>

            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-10 sm:h-11 text-xs sm:text-sm" onClick={() => { setIsAddOpen(false); setEditingIncome(null); }}>Cancel</Button>
              <Button onClick={handleSaveIncome} disabled={isSaving} className="flex-1 sm:flex-none px-6 sm:px-8 h-10 sm:h-11 text-xs sm:text-sm flex items-center justify-center shadow-md">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Income"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingIncome && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg sm:text-xl font-bold text-red-600">Delete Income</h2>
              <button onClick={() => setDeletingIncome(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 sm:p-8 flex-1 overflow-y-auto">
              <p className="font-medium text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this income record? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl sm:rounded-[1.5rem] border border-red-100 font-medium text-center">
                <span className="block text-[10px] sm:text-xs uppercase tracking-widest font-bold opacity-50 mb-1">{deletingIncome?.title}</span>
                <span className="text-3xl sm:text-4xl font-black block mt-2 tracking-tight">RM {formatPrice(deletingIncome?.price)}</span>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem] shrink-0">
              <Button variant="ghost" onClick={() => setDeletingIncome(null)} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 */}
      <div className="space-y-4 sm:space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Income</h1>
            <p className="text-sm font-medium text-sunset-dark/60 mt-1">Detailed view of your incoming transactions.</p>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={openAddModal} className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all">
              <Plus size={16} className="mr-1.5 shrink-0" /> Add Income
            </Button>
          </div>
        </header>

        <Card className="p-0 overflow-hidden shadow-xl shadow-orange-500/5 border-2 border-orange-500/20 flex flex-col min-h-0 rounded-[24px]">
          
          {/* Toolbar */}
          <div className="p-4 sm:p-6 border-b border-orange-500/10 flex flex-col xl:flex-row xl:items-center justify-between gap-4 bg-white shrink-0">
            
            {/* 搜索框组 - 在平板/手机端，清空与刷新图标完美放置在右侧且绝不换行 */}
            <div className="flex items-center gap-2 w-full xl:w-72 shrink-0">
              <div className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
                <Input 
                  placeholder="Search incomes..." 
                  className="pl-11 bg-white border border-orange-500/40 hover:border-orange-500 rounded-xl shadow-sm h-11 w-full focus:ring-2 focus:ring-orange-500/30 font-medium transition-all"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)} 
                  autoComplete="off" 
                />
              </div>
              
              {/* 【修复】：只在移动端/平板显示 (`xl:hidden`)，iPad Mini 下宽度设为 w-full，整行绝不换行重叠 */}
              <button 
                onClick={handleClearFilters} 
                className="xl:hidden h-11 px-3 bg-red-50 text-red-500 hover:bg-red-100 hover:text-red-600 rounded-xl transition-colors flex items-center justify-center shrink-0 border border-transparent hover:border-red-200" 
                title="Clear All Filters"
              >
                <FilterX size={18} />
              </button>
              <button 
                onClick={fetchIncomes} 
                className="xl:hidden h-11 px-3 bg-orange-50 text-orange-500 hover:bg-orange-100 hover:text-orange-600 rounded-xl transition-colors flex items-center justify-center shrink-0 border border-transparent hover:border-orange-200" 
                title="Refresh Table Data"
              >
                <RefreshCw size={18} className={isLoading ? "animate-spin" : ""} />
              </button>
            </div>
            
            {/* 筛选器容器 & 桌面端控制按钮容器 */}
            <div className="flex flex-col xl:flex-row items-center gap-3 w-full xl:w-auto xl:flex-1 xl:max-w-5xl xl:justify-end">
              
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 w-full xl:w-auto xl:flex-1">
                <div className="relative flex items-center w-full">
                  <Input 
                    type="date"
                    title="Start Date"
                    className={`bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30 w-full ${filterStartDate ? 'pr-8' : ''}`}
                    value={filterStartDate}
                    onChange={(e) => { setFilterStartDate(e.target.value); setCurrentPage(1); }}
                  />
                  {filterStartDate && (
                    <button 
                      onClick={() => { setFilterStartDate(""); setCurrentPage(1); }} 
                      className="absolute right-3 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <X size={14} />
                    </button>
                  )}
                </div>

                <div className="relative flex items-center w-full">
                  <Input 
                    type="date"
                    title="End Date"
                    className={`bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30 w-full ${filterEndDate ? 'pr-8' : ''}`}
                    value={filterEndDate}
                    onChange={(e) => { setFilterEndDate(e.target.value); setCurrentPage(1); }}
                  />
                  {filterEndDate && (
                    <button 
                      onClick={() => { setFilterEndDate(""); setCurrentPage(1); }} 
                      className="absolute right-3 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <X size={14} />
                    </button>
                  )}
                </div>

                <Select value={filterCategoryId} onValueChange={(val) => { setFilterCategoryId(val); setCurrentPage(1); }}>
                  <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                    <SelectValue placeholder="All Categories" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Categories</SelectItem>
                    {categoryOptions.map(c => <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>)}
                  </SelectContent>
                </Select>

                <Select value={filterMethodId} onValueChange={(val) => { setFilterMethodId(val); setCurrentPage(1); }}>
                  <SelectTrigger className="bg-white border-orange-500/80 hover:border-orange-500 rounded-xl h-11 text-xs font-bold text-sunset-dark shadow-sm transition-all focus:ring-2 focus:ring-orange-500/30">
                    <SelectValue placeholder="All Methods" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Methods</SelectItem>
                    {methodOptions.map(m => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                  </SelectContent>
                </Select>

              </div>

              {/* 【全新添加】在桌面端桌面视图 (`xl:flex`) 下，图标完美移至最右侧，解决 iPad 模拟器下的多余显示 */}
              <div className="hidden xl:flex items-center gap-2 shrink-0 pl-1">
                <button 
                  onClick={handleClearFilters} 
                  className="h-11 px-3 bg-red-50 text-red-500 hover:bg-red-100 hover:text-red-600 rounded-xl transition-colors flex items-center justify-center shrink-0 border border-transparent hover:border-red-200" 
                  title="Clear All Filters"
                >
                  <FilterX size={18} />
                </button>
                
                <button 
                  onClick={fetchIncomes} 
                  className="h-11 px-3 bg-orange-50 text-orange-500 hover:bg-orange-100 hover:text-orange-600 rounded-xl transition-colors flex items-center justify-center shrink-0 border border-transparent hover:border-orange-200" 
                  title="Refresh Table Data"
                >
                  <RefreshCw size={18} className={isLoading ? "animate-spin" : ""} />
                </button>
              </div>

            </div>
          </div>

          {/* Mobile & Tablet Portrait View (Cards) */}
          <div className="lg:hidden flex flex-col p-4 gap-4 bg-orange-50/20 max-h-[60vh] overflow-y-auto custom-scrollbar">
            {isLoading ? (
              <div className="text-center py-8"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></div>
            ) : incomes.map((inc) => (
               <div key={inc.id} className="bg-white p-4 rounded-2xl shadow-sm border border-orange-500/10 shadow-black/5 flex flex-col gap-3">
                  <div className="flex justify-between items-start">
                     <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-orange-400 to-red-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                          {getInitials(inc.title)}
                        </div>
                        <div>
                          <h3 className="font-extrabold text-sunset-dark text-base leading-tight line-clamp-1">{inc.title}</h3>
                          <p className="text-[10px] font-bold text-sunset-dark/40 mt-1 uppercase tracking-wider">{inc.date} • {inc.time}</p>
                        </div>
                     </div>
                     <span className="font-black text-lg text-emerald-600 bg-emerald-50 px-2 py-1 rounded-lg shrink-0">RM {formatPrice(inc.price)}</span>
                  </div>
                  
                  <div className="flex flex-wrap gap-1.5 mt-1 border-t border-orange-500/10 pt-3">
                     <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-orange-50 text-orange-600">
                       {inc.category?.name || 'Unknown'}
                     </span>
                     <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] sm:text-xs font-bold bg-slate-100 text-slate-600">
                       {inc.payment_method?.name || 'Unknown'}
                     </span>
                  </div>

                  <div className="flex gap-2 pt-2 mt-1">
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-blue-500 hover:bg-blue-50 transition-all border border-transparent" onClick={() => setViewingIncome(inc)}><Eye size={14} className="mr-1 inline"/> View</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-emerald-500 hover:bg-emerald-50 transition-all border border-transparent" onClick={() => openEditModal(inc)}><Edit2 size={14} className="mr-1 inline"/> Edit</Button>
                     <Button variant="ghost" className="flex-1 py-2 h-auto text-xs font-bold text-red-500 hover:bg-red-50 transition-all border border-transparent" onClick={() => setDeletingIncome(inc)}><Trash2 size={14} className="mr-1 inline"/> Delete</Button>
                  </div>
               </div>
            ))}
            {!isLoading && incomes.length === 0 && (
               <div className="text-center p-8 font-medium text-sunset-dark/40 bg-white rounded-2xl border border-orange-500/10">No incomes found matching criteria.</div>
            )}
          </div>

          {/* Desktop & Tablet Landscape View (Table) */}
          <div className="hidden lg:block overflow-x-auto custom-scrollbar">
            <table className="w-full text-left border-collapse min-w-[950px]">
              <thead>
                <tr className="bg-gradient-to-r from-orange-500 to-red-500 text-[10px] sm:text-xs font-black text-white uppercase tracking-widest border-b border-orange-500/20">
                  <th className="p-4 pl-6 whitespace-nowrap w-[18%] min-w-[150px]">Title</th>
                  <th className="p-4 whitespace-nowrap w-[18%] min-w-[150px]">Description</th>
                  <th className="p-4 whitespace-nowrap w-[14%] min-w-[120px]">Amount (RM)</th>
                  <th className="p-4 whitespace-nowrap w-[10%] min-w-[100px]">Date</th>
                  <th className="p-4 whitespace-nowrap w-[10%] min-w-[100px]">Time</th>
                  <th className="p-4 whitespace-nowrap w-[10%] min-w-[100px]">Method</th>
                  <th className="p-4 whitespace-nowrap w-[10%] min-w-[100px]">Category</th>
                  <th className="p-4 text-center pr-6 w-[10%] min-w-[120px]">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-orange-500/10">
                {isLoading ? (
                  <tr>
                    <td colSpan={8} className="p-12 text-center"><Loader2 className="animate-spin text-orange-500 mx-auto w-8 h-8" /></td>
                  </tr>
                ) : incomes.map((inc) => (
                  <tr key={inc.id} className="hover:bg-orange-50/40 transition-colors">
                    <td className="p-4 pl-6 font-bold text-sunset-dark">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-orange-400 to-red-500 text-white flex items-center justify-center font-bold text-sm uppercase shrink-0">
                          {getInitials(inc.title)}
                        </div>
                        <span className="truncate max-w-[150px] block" title={inc.title}>{inc.title}</span>
                      </div>
                    </td>
                    <td className="p-4 font-medium text-sunset-dark/70 text-sm truncate max-w-[200px]" title={inc.description}>
                      {inc.description || <span className="text-gray-400 italic">N/A</span>}
                    </td>
                    
                    {/* 【优化】：通过 formatPrice 去掉无意义的 .00 */}
                    <td className="p-4 font-black text-emerald-600 text-lg">RM&nbsp;{formatPrice(inc.price)}</td>
                    
                    <td className="p-4 font-semibold text-sunset-dark/90 text-sm whitespace-nowrap">
                      {inc.date}
                    </td>
                    <td className="p-4">
                      <span className="inline-flex py-1 px-2 rounded text-[10px] font-bold bg-orange-50 text-orange-700 uppercase tracking-wider whitespace-nowrap">
                        {inc.time}
                      </span>
                    </td>
                    
                    <td className="p-4">
                      <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] font-bold bg-slate-100 text-slate-600 whitespace-nowrap">
                        {inc.payment_method?.name || 'N/A'}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className="inline-flex py-1 px-2.5 rounded-lg text-[10px] font-bold bg-orange-50 text-orange-600 whitespace-nowrap">
                        {inc.category?.name || 'N/A'}
                      </span>
                    </td>
                    <td className="p-4 pr-6">
                      <div className="flex items-center justify-center gap-1">
                         <button onClick={() => setViewingIncome(inc)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-500/10 rounded-xl transition-colors" title="View"><Eye size={18} /></button>
                         <button onClick={() => openEditModal(inc)} className="p-2 text-sunset-dark/40 hover:text-emerald-500 hover:bg-emerald-500/10 rounded-xl transition-colors" title="Edit"><Edit2 size={18} /></button>
                         <button onClick={() => setDeletingIncome(inc)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors" title="Delete"><Trash2 size={18} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!isLoading && incomes.length === 0 && (
                  <tr>
                    <td colSpan={8} className="p-12 text-center text-sunset-dark/40 font-medium">No incomes found matching your search.</td>
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
                     <button key={i} onClick={() => setCurrentPage(i + 1)} className={`relative inline-flex items-center justify-center w-9 h-9 rounded-xl text-sm font-bold transition-all ${currentPage === i + 1 ? 'bg-orange-500/10 text-orange-600 ring-1 ring-inset ring-orange-500/30' : 'text-sunset-dark/60 hover:bg-orange-50/50 ring-1 ring-inset ring-orange-500/10'}`}>
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
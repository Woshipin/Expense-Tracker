"use client";

import React, { useState, useEffect } from "react";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Loader2, X, Layers } from "lucide-react";
import api from "@/lib/axios";

export default function TypesPage() {
  const [types, setTypes] = useState<any[]>([]);
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingType, setViewingType] = useState<any>(null);
  const [editingType, setEditingType] = useState<any>(null);
  const [deletingType, setDeletingType] = useState<any>(null);
  
  // Search & Filter
  const [searchQuery, setSearchQuery] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Loading States
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Form Fields State
  const [formData, setFormData] = useState({
    name: "", 
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

  const fetchTypes = async () => {
    setIsLoading(true);
    try {
      const params: any = { page: currentPage };
      if (searchQuery) params.search = searchQuery;
      if (filterStatus !== "all") params.status = filterStatus;

      const response = await api.get('/types', { params });
      setTypes(response.data.data || response.data); 
      setTotalPages(response.data.last_page || 1);
    } catch (error) {
      showToast("Failed to fetch types.", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchTypes();
  }, [currentPage, filterStatus]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      setCurrentPage(1);
      fetchTypes();
    }, 500);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery]);

  const openAddModal = () => {
    setErrors({});
    setFormData({ name: "", status: "1" });
    setIsAddOpen(true);
  };

  const openEditModal = (t: any) => {
    setErrors({});
    setFormData({ 
      name: t.name, 
      status: String(t.status) 
    });
    setEditingType(t);
  };

  const handleSaveType = async () => {
    setIsSaving(true);
    setErrors({});
    
    try {
      if (editingType) {
        await api.put(`/types/${editingType.id}`, formData);
        showToast('Type updated successfully!', 'success');
        setEditingType(null);
      } else {
        await api.post('/types', formData);
        showToast('Type added successfully!', 'success');
        setIsAddOpen(false);
      }
      fetchTypes();
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
      await api.delete(`/types/${deletingType.id}`);
      showToast('Type deleted successfully', 'success');
      setDeletingType(null);
      fetchTypes();
    } catch (error: any) {
      showToast(error.response?.data?.message || error.response?.data?.error || "Failed to delete type", "error");
      setDeletingType(null);
    }
  };

  return (
    <>
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. View Modal */}
      {viewingType && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-6 py-5 border-b border-orange-500/10 flex justify-between items-center bg-gray-50/50">
              <h2 className="text-xl font-black text-sunset-dark">Type Details</h2>
              <button onClick={() => setViewingType(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-8 flex flex-col items-center text-center gap-4">
              <div className="w-20 h-20 rounded-2xl flex items-center justify-center shadow-sm bg-orange-50 text-orange-500 mb-2">
                <Layers className="w-10 h-10" />
              </div>
              <div>
                <h3 className="text-2xl font-extrabold text-sunset-dark">{viewingType.name}</h3>
                <span className={`inline-flex mt-2 py-1 px-3 rounded-lg text-xs font-bold uppercase tracking-wider ${
                  String(viewingType.status) === '1' ? 'bg-emerald-50 text-emerald-600' : 'bg-gray-100 text-gray-500'
                }`}>
                  {String(viewingType.status) === '1' ? 'Active' : 'Inactive'}
                </span>
              </div>
            </div>
            <div className="px-6 py-5 border-t border-orange-500/10 flex justify-end bg-gray-50/50">
              <Button onClick={() => setViewingType(null)} className="w-full shadow-sm bg-sunset-dark text-white hover:bg-black rounded-xl">Close</Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit Form Modal */}
      {(isAddOpen || editingType) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-6 py-5 border-b border-orange-500/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingType ? "Edit Type" : "Add Type"}</h2>
              <button onClick={() => { setIsAddOpen(false); setEditingType(null); }} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar space-y-5">
              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Type Name</label>
                <Input 
                  placeholder="E.g. Expense, Income" 
                  value={formData.name} 
                  onChange={(e) => setFormData({...formData, name: e.target.value})} 
                  className="h-11 text-sm bg-white" 
                  autoComplete="off" 
                />
                {errors.name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.name[0]}</p>}
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
                {errors.status && <p className="text-xs text-red-500 mt-1 pl-1">{errors.status[0]}</p>}
              </div>
            </div>

            <div className="px-6 py-5 border-t border-orange-500/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-11 text-sm bg-white border rounded-xl" onClick={() => { setIsAddOpen(false); setEditingType(null); }}>Cancel</Button>
              <Button onClick={handleSaveType} disabled={isSaving} className="flex-1 sm:flex-none px-8 h-11 text-sm flex items-center justify-center shadow-md bg-orange-500 text-white hover:bg-orange-600 rounded-xl">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Type"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingType && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl flex flex-col overflow-hidden">
            <div className="px-6 py-5 border-b border-orange-500/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg font-black text-red-600">Delete Type</h2>
              <button onClick={() => setDeletingType(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 flex-1">
              <p className="font-semibold text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this type? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-bold flex items-center gap-3">
                 <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
                   <Layers size={20} />
                 </div>
                 <div>
                   <span className="block text-[10px] uppercase tracking-widest font-black opacity-50">Deleting Type</span>
                   <span className="text-lg font-black block mt-0.5">{deletingType.name}</span>
                 </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-orange-500/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 shrink-0">
              <Button variant="ghost" onClick={() => setDeletingType(null)} className="flex-1 sm:flex-none text-sm h-11 border bg-white shadow-sm rounded-xl">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-sm h-11 shadow-md rounded-xl">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 */}
      <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Transaction Types</h1>
            <p className="text-sm font-semibold text-sunset-dark/60 mt-1">Manage global transaction types (e.g. Income, Expense).</p>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={openAddModal} className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all bg-orange-500 text-white hover:bg-orange-600 rounded-xl">
              <Plus size={16} className="mr-1.5 shrink-0" /> Add Type
            </Button>
          </div>
        </header>

        {/* Toolbar */}
        <div className="flex flex-col md:flex-row items-center gap-4 bg-white p-4 rounded-3xl border border-orange-500/10 shadow-sm">
          <div className="relative w-full md:flex-1 shrink-0">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
            <Input 
              placeholder="Search types..." 
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

        {/* 列表渲染 */}
        {isLoading ? (
          <div className="text-center py-20 bg-white rounded-[24px] border border-gray-100 shadow-sm"><Loader2 className="animate-spin text-orange-500 mx-auto w-10 h-10" /></div>
        ) : types.length === 0 ? (
          <div className="text-center py-20 font-semibold text-gray-400 bg-white rounded-[24px] border border-gray-100 shadow-sm">No types found.</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {types.map((t) => (
              <div key={t.id} className="bg-white p-5 rounded-3xl border border-gray-100 shadow-sm hover:border-orange-500/30 hover:shadow-md transition-all group flex flex-col justify-between">
                
                <div className="flex items-start justify-between mb-4">
                   <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-sm bg-orange-50 text-orange-500">
                     <Layers size={20} />
                   </div>
                   {/* 操作按钮 (常驻，不再 hover 隐藏) */}
                   <div className="flex gap-1.5">
                     <button onClick={() => setViewingType(t)} className="w-8 h-8 rounded-full flex items-center justify-center bg-gray-50 text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition-colors"><Eye size={14}/></button>
                     <button onClick={() => openEditModal(t)} className="w-8 h-8 rounded-full flex items-center justify-center bg-gray-50 text-gray-400 hover:text-emerald-500 hover:bg-emerald-50 transition-colors"><Edit2 size={14}/></button>
                     <button onClick={() => setDeletingType(t)} className="w-8 h-8 rounded-full flex items-center justify-center bg-gray-50 text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"><Trash2 size={14}/></button>
                   </div>
                </div>

                <div>
                  <h3 className="font-extrabold text-sunset-dark text-lg truncate">{t.name}</h3>
                  <div className="mt-2">
                    <span className={`inline-flex py-1 px-2.5 rounded-lg text-[10px] font-bold uppercase tracking-wider ${
                      String(t.status) === '1' ? 'bg-emerald-50 text-emerald-600' : 'bg-gray-100 text-gray-500'
                    }`}>
                      {String(t.status) === '1' ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                </div>

              </div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border border-gray-100 shadow-sm rounded-3xl bg-white overflow-x-auto hide-scroll shrink-0 mt-auto">
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
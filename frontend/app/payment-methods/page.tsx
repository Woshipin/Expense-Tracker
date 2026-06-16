"use client";

import { Card, Button, Input, Modal, Toast } from "@/components/ui";
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight } from "lucide-react";
import { useState } from "react";

export default function PaymentMethodsPage() {
  const [methods, setMethods] = useState([
    { id: 1, name: 'Cash', description: 'Physical currency', status: 'Active' },
    { id: 2, name: 'Debit Card', description: 'Bank debit card', status: 'Active' },
    { id: 3, name: 'Credit Card', description: 'Visa / Mastercard', status: 'Active' },
    { id: 4, name: 'Apple Pay', description: 'Apple wallet integration', status: 'Active' },
    { id: 5, name: 'Touch n Go', description: 'TNG eWallet', status: 'Active' },
  ]);

  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingMethod, setViewingMethod] = useState<any>(null);
  const [editingMethod, setEditingMethod] = useState<any>(null);
  const [deletingMethod, setDeletingMethod] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState("");
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const filteredMethods = methods.filter(m => m.name.toLowerCase().includes(searchQuery.toLowerCase()));
  const totalPages = Math.max(1, Math.ceil(filteredMethods.length / itemsPerPage));
  const paginatedMethods = filteredMethods.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleDelete = () => {
    setMethods(methods.filter(m => m.id !== deletingMethod.id));
    setDeletingMethod(null);
    showToast('Payment method deleted successfully', 'success');
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      {/* View Modal */}
      <Modal isOpen={!!viewingMethod} onClose={() => setViewingMethod(null)} title="View Payment Method Details">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 p-2">
          {/* Left Side */}
          <div className="space-y-4">
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Name</label>
              <div className="font-bold text-sunset-dark text-lg">{viewingMethod?.name}</div>
            </div>
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Description</label>
              <div className="font-medium text-sunset-dark/80">{viewingMethod?.description || '-'}</div>
            </div>
          </div>
          {/* Right Side */}
          <div className="space-y-4 md:border-l md:border-sunset-primary/10 md:pl-6">
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Status</label>
              <div className="inline-flex py-1 px-3 rounded-full text-sm font-bold bg-green-50 text-green-600">{viewingMethod?.status}</div>
            </div>
          </div>
        </div>
        <div className="flex justify-end pt-6 mt-6 border-t border-sunset-primary/10">
          <Button onClick={() => setViewingMethod(null)}>Close</Button>
        </div>
      </Modal>

      {/* Add / Edit Modal */}
      <Modal isOpen={isAddOpen || !!editingMethod} onClose={() => { setIsAddOpen(false); setEditingMethod(null); }} title={editingMethod ? "Edit Payment Method" : "Add Payment Method"}>
        <div className="space-y-4">
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Name</label><Input placeholder="E.g., Credit Card" defaultValue={editingMethod?.name} /></div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Description</label><Input placeholder="Brief description" defaultValue={editingMethod?.description} /></div>
          <div>
             <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Status</label>
              <Select defaultValue={editingMethod?.status || 'Active'}>
               <SelectTrigger className="w-full bg-sunset-bg/50 h-11 border-sunset-primary/10 rounded-2xl text-sunset-dark font-medium transition-shadow mx-0">
                 <SelectValue placeholder="Status" />
               </SelectTrigger>
               <SelectContent>
                 <SelectGroup>
                   <SelectItem value="Active">Active</SelectItem>
                   <SelectItem value="Inactive">Inactive</SelectItem>
                 </SelectGroup>
               </SelectContent>
              </Select>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => { setIsAddOpen(false); setEditingMethod(null); }}>Cancel</Button>
            <Button onClick={() => { setIsAddOpen(false); setEditingMethod(null); showToast(editingMethod ? 'Payment method updated successfully!' : 'Payment method added successfully!'); }}>Save Method</Button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal isOpen={!!deletingMethod} onClose={() => setDeletingMethod(null)} title="Delete Payment Method">
        <div className="space-y-4">
          <p className="font-medium text-sunset-dark">Are you sure you want to delete this payment method? This action cannot be undone.</p>
          <div className="p-4 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-medium pb-2">
            <span className="block text-sm uppercase tracking-widest font-bold opacity-50 mb-1">Deleting Method:</span>
            <span className="text-xl font-black block mt-2">{deletingMethod?.name}</span>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => setDeletingMethod(null)}>Cancel</Button>
            <Button variant="danger" onClick={handleDelete}>Delete Permanently</Button>
          </div>
        </div>
      </Modal>

      <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Payment Methods</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage your payment methods.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={() => setIsAddOpen(true)} className="px-4 py-2 text-sm h-auto"><Plus size={16} className="mr-2 hidden sm:inline" /> Add Method</Button>
        </div>
      </header>

      <Card className="p-0 overflow-hidden shadow-md shadow-black/5 border-sunset-primary/10 flex flex-col min-h-0">
        {/* Toolbar */}
        <div className="p-4 sm:p-6 border-b border-sunset-primary/10 flex flex-col xl:flex-row xl:items-center gap-3 sm:gap-4 bg-white shrink-0">
          <div className="relative w-full xl:w-72 shrink-0">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
            <Input 
              placeholder="Search..." 
              className="pl-11 bg-white border border-black/10 rounded-xl shadow-sm h-12 lg:h-11 w-full focus:ring-2 focus:ring-sunset-primary/30 font-semibold"
              value={searchQuery}
              onChange={(e) => {setSearchQuery(e.target.value); setCurrentPage(1);}} 
            />
          </div>
        </div>

        {/* Mobile View (Cards) */}
        <div className="md:hidden flex flex-col p-4 gap-4 bg-sunset-bg/20">
          {paginatedMethods.map((m) => (
             <div key={m.id} className="bg-white p-4 rounded-2xl shadow-sm border border-sunset-primary/10 shadow-black/5 flex flex-col gap-3">
                <div className="flex justify-between items-start">
                   <div>
                      <h3 className="font-bold text-sunset-dark text-lg">{m.name}</h3>
                      <p className="text-sm font-medium text-sunset-dark/60">{m.description}</p>
                   </div>
                </div>
                <div className="flex flex-wrap gap-2 text-xs font-bold mt-1">
                   <div className="bg-green-50 text-green-600 px-2 py-1 rounded-md">{m.status}</div>
                </div>
                <div className="flex gap-2 pt-3 mt-1 border-t border-sunset-primary/5">
                   <Button variant="secondary" className="flex-1 py-2 h-auto text-sm" onClick={() => setViewingMethod(m)}><Eye size={14} className="mr-1.5 inline"/> View</Button>
                   <Button variant="secondary" className="flex-1 py-2 h-auto text-sm" onClick={() => setEditingMethod(m)}><Edit2 size={14} className="mr-1.5 inline"/> Edit</Button>
                   <Button variant="ghost" className="flex-1 py-2 h-auto text-sm text-red-500 hover:text-red-600 hover:bg-red-50 bg-red-50/50" onClick={() => setDeletingMethod(m)}><Trash2 size={14} className="mr-1.5 inline"/> Delete</Button>
                </div>
             </div>
          ))}
          {paginatedMethods.length === 0 && (
             <div className="text-center p-8 font-medium text-sunset-dark/40 bg-white rounded-2xl border border-sunset-primary/10">No payment methods found matching criteria.</div>
          )}
        </div>

        {/* Desktop View (Table) */}
        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[700px]">
            <thead>
              <tr className="bg-sunset-primary/5 text-[10px] sm:text-xs font-bold text-sunset-dark/60 uppercase tracking-widest border-y border-sunset-primary/10">
                <th className="p-4 pl-6 whitespace-nowrap w-[25%]">Name</th>
                <th className="p-4 whitespace-nowrap w-[40%]">Description</th>
                <th className="p-4 whitespace-nowrap">Status</th>
                <th className="p-4 text-center pr-6 w-[120px]">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-sunset-primary/5">
              {paginatedMethods.map((m) => (
                <tr key={m.id} className="hover:bg-sunset-primary/5 transition-colors">
                  <td className="p-4 pl-6 font-bold text-sunset-dark">{m.name}</td>
                  <td className="p-4 font-medium text-sunset-dark/70 text-sm">{m.description}</td>
                  <td className="p-4">
                    <span className="inline-flex py-1 px-2.5 rounded-full text-xs font-bold bg-green-50 text-green-600">{m.status}</span>
                  </td>
                  <td className="p-4 pr-6">
                    <div className="flex items-center justify-center gap-1">
                       <button onClick={() => setViewingMethod(m)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-500/10 rounded-xl transition-colors" title="View"><Eye size={18} /></button>
                       <button onClick={() => setEditingMethod(m)} className="p-2 text-sunset-dark/40 hover:text-emerald-500 hover:bg-emerald-500/10 rounded-xl transition-colors" title="Edit"><Edit2 size={18} /></button>
                       <button onClick={() => setDeletingMethod(m)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors" title="Delete"><Trash2 size={18} /></button>
                    </div>
                  </td>
                </tr>
              ))}
              {paginatedMethods.length === 0 && (
                <tr>
                  <td colSpan={4} className="p-12 text-center text-sunset-dark/40 font-medium">No payment methods found matching your search.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        
        {/* Pagination Element */}
        {totalPages > 0 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-sunset-primary/10 overflow-x-auto hide-scroll shrink-0 mt-auto">
            <div className="hidden sm:block shrink-0">
              <p className="text-sm text-sunset-dark/60 font-medium tracking-tight">
                Page <span className="font-bold text-sunset-dark">{currentPage}</span> of <span className="font-bold text-sunset-dark">{totalPages}</span>
              </p>
            </div>
            <div className="flex gap-2">
              <button onClick={() => setCurrentPage(Math.max(1, currentPage - 1))} disabled={currentPage === 1} className="relative inline-flex items-center rounded-xl bg-white px-3 py-2 text-sm font-bold text-sunset-dark/60 ring-1 ring-inset ring-sunset-primary/20 hover:bg-sunset-bg focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"><ChevronLeft size={16} /></button>
              <div className="flex items-center gap-1">
                {[...Array(totalPages)].map((_, i) => (
                   <button key={i} onClick={() => setCurrentPage(i + 1)} className={`relative inline-flex items-center justify-center w-9 h-9 rounded-xl text-sm font-bold transition-all ${currentPage === i + 1 ? 'bg-sunset-primary/10 text-sunset-primary ring-1 ring-inset ring-sunset-primary/30' : 'text-sunset-dark/60 hover:bg-sunset-bg ring-1 ring-inset ring-sunset-primary/20'}`}>
                     {i + 1}
                   </button>
                ))}
              </div>
              <button onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))} disabled={currentPage === totalPages} className="relative inline-flex items-center rounded-xl bg-white px-3 py-2 text-sm font-bold text-sunset-dark/60 ring-1 ring-inset ring-sunset-primary/20 hover:bg-sunset-bg focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"><ChevronRight size={16} /></button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}

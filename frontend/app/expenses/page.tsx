"use client";

import { Card, Button, Input, Modal, Toast } from "@/components/ui";
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Search, Filter, Plus, Edit2, Trash2, Eye, ChevronLeft, ChevronRight, Calendar, ChevronDown } from "lucide-react";
import { useState } from "react";

const PAYMENT_METHODS = [
  'Credit Card', 'Debit Card', 'TNG', 'Cash', 'Online Transfer', 'Online Pay', 'Other Pay'
];

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState([
    { id: 1, title: 'Weekly Groceries', description: 'Bought at Whole Foods Market', date: '2023-10-25', time: '14:45', price: 124.50, payment_method: 'Credit Card', category: 'Groceries' },
    { id: 2, title: 'Airport Ride', description: 'Uber ride to airport terminal', date: '2023-10-24', time: '18:30', price: 24.00, payment_method: 'TNG', category: 'Transport' },
    { id: 3, title: 'Morning Coffee', description: 'Starbucks latte', date: '2023-10-24', time: '08:15', price: 5.50, payment_method: 'Credit Card', category: 'Food' },
    { id: 4, title: 'Netflix Sub', description: 'Monthly subscription', date: '2023-10-23', time: '10:00', price: 15.99, payment_method: 'Credit Card', category: 'Entertainment' },
  ]);

  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [viewingExpense, setViewingExpense] = useState<any>(null);
  const [editingExpense, setEditingExpense] = useState<any>(null);
  const [deletingExpense, setDeletingExpense] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState("");
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const filteredExpenses = expenses.filter(e => e.title.toLowerCase().includes(searchQuery.toLowerCase()));
  const totalPages = Math.max(1, Math.ceil(filteredExpenses.length / itemsPerPage));
  const paginatedExpenses = filteredExpenses.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleDelete = () => {
    setExpenses(expenses.filter(e => e.id !== deletingExpense.id));
    setDeletingExpense(null);
    showToast('Expense record deleted successfully', 'success');
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      {/* View Modal */}
      <Modal isOpen={!!viewingExpense} onClose={() => setViewingExpense(null)} title="View Expense Details">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 p-2">
          {/* Left Side */}
          <div className="space-y-4">
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Title</label>
              <div className="font-bold text-sunset-dark text-lg">{viewingExpense?.title}</div>
            </div>
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Description</label>
              <div className="font-medium text-sunset-dark/80">{viewingExpense?.description || '-'}</div>
            </div>
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Category</label>
              <div className="inline-flex py-1 px-3 rounded-md text-sm font-bold bg-sunset-primary/10 text-sunset-primary">{viewingExpense?.category}</div>
            </div>
          </div>
          {/* Right Side */}
          <div className="space-y-4 md:border-l md:border-sunset-primary/10 md:pl-6">
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Amount</label>
              <div className="font-black text-2xl text-sunset-dark">RM {viewingExpense?.price?.toFixed(2)}</div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Date</label>
                <div className="font-medium text-sunset-dark/80">{viewingExpense?.date}</div>
              </div>
              <div>
                <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Time</label>
                <div className="font-medium text-sunset-dark/80">{viewingExpense?.time}</div>
              </div>
            </div>
            <div>
              <label className="text-xs font-bold text-sunset-dark/50 uppercase tracking-widest block mb-1">Payment Method</label>
              <div className="inline-flex py-1 px-3 rounded-full text-sm font-bold bg-sunset-dark/5 text-sunset-dark/70">{viewingExpense?.payment_method}</div>
            </div>
          </div>
        </div>
        <div className="flex justify-end pt-6 mt-6 border-t border-sunset-primary/10">
          <Button onClick={() => setViewingExpense(null)}>Close</Button>
        </div>
      </Modal>

      {/* Add / Edit Modal */}
      <Modal isOpen={isAddOpen || !!editingExpense} onClose={() => { setIsAddOpen(false); setEditingExpense(null); }} title={editingExpense ? "Edit Expense" : "Add Expense"}>
        <div className="space-y-4">
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Title</label><Input placeholder="E.g., Groceries" defaultValue={editingExpense?.title} /></div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Description</label><Input placeholder="Brief description" defaultValue={editingExpense?.description} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Date</label><Input type="date" defaultValue={editingExpense?.date} /></div>
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Time</label><Input type="time" defaultValue={editingExpense?.time} /></div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Price (RM)</label><Input type="number" placeholder="0.00" defaultValue={editingExpense?.price} /></div>
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Category</label><Input placeholder="Category" defaultValue={editingExpense?.category} /></div>
          </div>
          <div>
             <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Payment Method</label>
              <Select defaultValue={editingExpense?.payment_method || 'Credit Card'}>
               <SelectTrigger className="w-full bg-sunset-bg/50 h-11 border-sunset-primary/10 rounded-2xl text-sunset-dark font-medium transition-shadow mx-0">
                 <SelectValue placeholder="Select Method" />
               </SelectTrigger>
               <SelectContent>
                 <SelectGroup>
                   {PAYMENT_METHODS.map(m => (<SelectItem key={m} value={m}>{m}</SelectItem>))}
                 </SelectGroup>
               </SelectContent>
              </Select>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => { setIsAddOpen(false); setEditingExpense(null); }}>Cancel</Button>
            <Button onClick={() => { setIsAddOpen(false); setEditingExpense(null); showToast(editingExpense ? 'Expense updated successfully!' : 'Expense added successfully!'); }}>Save Expense</Button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal isOpen={!!deletingExpense} onClose={() => setDeletingExpense(null)} title="Delete Expense">
        <div className="space-y-4">
          <p className="font-medium text-sunset-dark">Are you sure you want to delete this expense record? This action cannot be undone.</p>
          <div className="p-4 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-medium pb-2">
            <span className="block text-sm uppercase tracking-widest font-bold opacity-50 mb-1">Deleting record:</span>
            {deletingExpense?.title} <br/>
            <span className="text-2xl font-black block mt-2">RM {deletingExpense?.price.toFixed(2)}</span>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => setDeletingExpense(null)}>Cancel</Button>
            <Button variant="danger" onClick={handleDelete}>Delete Permanently</Button>
          </div>
        </div>
      </Modal>

      <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Expenses</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Detailed view of your outgoing transactions.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={() => setIsAddOpen(true)} className="px-4 py-2 text-sm h-auto"><Plus size={16} className="mr-2 hidden sm:inline" /> Add Expense</Button>
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
          <div className="grid grid-cols-2 xl:flex gap-3 items-center w-full">
            <Select>
              <SelectTrigger className="w-full relative pl-10 h-10">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"><Calendar className="text-sunset-dark/40" size={16} /></div>
                <SelectValue placeholder="Start Date" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="any">Any Date</SelectItem>
                  <SelectItem value="today">Today</SelectItem>
                  <SelectItem value="yesterday">Yesterday</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>

            <Select>
              <SelectTrigger className="w-full relative pl-10 h-10">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"><Calendar className="text-sunset-dark/40" size={16} /></div>
                <SelectValue placeholder="End Date" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="any">Any Date</SelectItem>
                  <SelectItem value="today">Today</SelectItem>
                  <SelectItem value="yesterday">Yesterday</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>

            <Select>
              <SelectTrigger className="w-full relative pl-10 h-10">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"><Filter className="text-sunset-dark/40" size={16} /></div>
                <SelectValue placeholder="Category" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="all">All Categories</SelectItem>
                  <SelectItem value="groceries">Groceries</SelectItem>
                  <SelectItem value="transport">Transport</SelectItem>
                  <SelectItem value="food">Food</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>

            <Select>
              <SelectTrigger className="w-full relative pl-10 h-10">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"><Filter className="text-sunset-dark/40" size={16} /></div>
                <SelectValue placeholder="Method" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="all">All Methods</SelectItem>
                  <SelectItem value="card">Credit Card</SelectItem>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="tng">TNG</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* Mobile View (Cards) */}
        <div className="md:hidden flex flex-col p-4 gap-4 bg-sunset-bg/20">
          {paginatedExpenses.map((exp) => (
             <div key={exp.id} className="bg-white p-4 rounded-2xl shadow-sm border border-sunset-primary/10 shadow-black/5 flex flex-col gap-3">
                <div className="flex justify-between items-start">
                   <div>
                      <h3 className="font-bold text-sunset-dark text-lg">{exp.title}</h3>
                      <p className="text-sm font-medium text-sunset-dark/60">{exp.description}</p>
                   </div>
                   <span className="font-black text-lg text-sunset-dark bg-sunset-primary/5 px-2 py-1 rounded-lg">RM {exp.price.toFixed(2)}</span>
                </div>
                <div className="flex flex-wrap gap-2 text-xs font-bold mt-1">
                   <div className="bg-black/5 px-2 py-1 rounded-md text-sunset-dark/60">{exp.category}</div>
                   <div className="bg-black/5 px-2 py-1 rounded-md text-sunset-dark/60">{exp.payment_method}</div>
                   <div className="bg-black/5 px-2 py-1 rounded-md text-sunset-dark/60">{exp.date} • {exp.time}</div>
                </div>
                <div className="flex gap-2 pt-3 mt-1 border-t border-sunset-primary/5">
                   <Button variant="secondary" className="flex-1 py-2 h-auto text-sm" onClick={() => setViewingExpense(exp)}><Eye size={14} className="mr-1.5 inline"/> View</Button>
                   <Button variant="secondary" className="flex-1 py-2 h-auto text-sm" onClick={() => setEditingExpense(exp)}><Edit2 size={14} className="mr-1.5 inline"/> Edit</Button>
                   <Button variant="ghost" className="flex-1 py-2 h-auto text-sm text-red-500 hover:text-red-600 hover:bg-red-50 bg-red-50/50" onClick={() => setDeletingExpense(exp)}><Trash2 size={14} className="mr-1.5 inline"/> Delete</Button>
                </div>
             </div>
          ))}
          {paginatedExpenses.length === 0 && (
             <div className="text-center p-8 font-medium text-sunset-dark/40 bg-white rounded-2xl border border-sunset-primary/10">No expenses found matching criteria.</div>
          )}
        </div>

        {/* Desktop View (Table) */}
        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[900px]">
            <thead>
              <tr className="bg-sunset-primary/5 text-[10px] sm:text-xs font-bold text-sunset-dark/60 uppercase tracking-widest border-y border-sunset-primary/10">
                <th className="p-4 pl-6 whitespace-nowrap w-[15%]">Title</th>
                <th className="p-4 whitespace-nowrap w-[20%]">Description</th>
                <th className="p-4 whitespace-nowrap">Price (RM)</th>
                <th className="p-4 whitespace-nowrap">Date</th>
                <th className="p-4 whitespace-nowrap">Time</th>
                <th className="p-4 whitespace-nowrap">Method</th>
                <th className="p-4 whitespace-nowrap">Category</th>
                <th className="p-4 text-center pr-6 w-[120px]">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-sunset-primary/5">
              {paginatedExpenses.map((exp) => (
                <tr key={exp.id} className="hover:bg-sunset-primary/5 transition-colors">
                  <td className="p-4 pl-6 font-bold text-sunset-dark truncate max-w-[150px]">{exp.title}</td>
                  <td className="p-4 font-medium text-sunset-dark/70 text-sm truncate max-w-[200px]">{exp.description}</td>
                  <td className="p-4 font-black text-sunset-dark">RM&nbsp;{exp.price.toFixed(2)}</td>
                  <td className="p-4 font-medium text-sunset-dark/80 text-sm whitespace-nowrap">{exp.date}</td>
                  <td className="p-4 font-medium text-sunset-dark/80 text-sm whitespace-nowrap">{exp.time}</td>
                  <td className="p-4">
                    <span className="inline-flex py-1 px-2.5 rounded-full text-xs font-bold bg-sunset-dark/5 text-sunset-dark/70 whitespace-nowrap">{exp.payment_method}</span>
                  </td>
                  <td className="p-4">
                    <span className="inline-flex py-1 px-2.5 rounded-md text-xs font-bold bg-sunset-primary/10 text-sunset-primary whitespace-nowrap">{exp.category}</span>
                  </td>
                  <td className="p-4 pr-6">
                    <div className="flex items-center justify-center gap-1">
                       <button onClick={() => setViewingExpense(exp)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-500/10 rounded-xl transition-colors" title="View"><Eye size={18} /></button>
                       <button onClick={() => setEditingExpense(exp)} className="p-2 text-sunset-dark/40 hover:text-emerald-500 hover:bg-emerald-500/10 rounded-xl transition-colors" title="Edit"><Edit2 size={18} /></button>
                       <button onClick={() => setDeletingExpense(exp)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors" title="Delete"><Trash2 size={18} /></button>
                    </div>
                  </td>
                </tr>
              ))}
              {paginatedExpenses.length === 0 && (
                <tr>
                  <td colSpan={8} className="p-12 text-center text-sunset-dark/40 font-medium">No expenses found matching your search.</td>
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

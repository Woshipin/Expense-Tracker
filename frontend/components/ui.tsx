import { cn } from "@/lib/utils";
import React from "react";
import { X, CheckCircle2, AlertCircle, AlertTriangle } from "lucide-react";

export function Card({ className, children, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn("bg-white rounded-3xl p-4 md:p-6 shadow-sm border border-sunset-primary/10", className)} {...props}>
      {children}
    </div>
  );
}

export function Button({ className, variant = 'primary', ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' | 'ghost' | 'fab' | 'danger' }) {
  const variants = {
    primary: "bg-sunset-primary text-white hover:bg-sunset-secondary rounded-2xl px-6 py-3 font-semibold transition-colors shadow-lg shadow-sunset-primary/30",
    secondary: "bg-sunset-primary/10 text-sunset-primary hover:bg-sunset-primary/20 rounded-2xl px-6 py-3 font-semibold transition-colors",
    ghost: "bg-transparent text-sunset-dark/60 hover:text-sunset-dark hover:bg-black/5 rounded-2xl px-6 py-3 font-semibold transition-colors",
    danger: "bg-red-500 text-white hover:bg-red-600 rounded-2xl px-6 py-3 font-semibold transition-colors shadow-lg shadow-red-500/30",
    fab: "bg-sunset-primary text-white hover:bg-sunset-secondary rounded-full p-4 font-semibold transition-colors shadow-lg shadow-sunset-primary/30 flex items-center justify-center",
  };
  return <button className={cn(variants[variant], className)} {...props} />;
}

export function Input({ className, ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input 
      className={cn("w-full bg-sunset-bg/50 border border-sunset-primary/10 rounded-2xl px-4 py-3 outline-none focus:border-sunset-primary/40 focus:bg-white transition-all text-sunset-dark placeholder:text-sunset-dark/30 font-medium", className)} 
      {...props} 
    />
  );
}

export function Toast({ message, type, onClose }: { message: string, type: 'success'|'error'|'warning', onClose: () => void }) {
  const config = {
    success: { bg: 'bg-green-50', border: 'border-green-200', text: 'text-green-800', icon: <CheckCircle2 className="text-green-500" size={18} /> },
    error: { bg: 'bg-red-50', border: 'border-red-200', text: 'text-red-800', icon: <AlertCircle className="text-red-500" size={18} /> },
    warning: { bg: 'bg-orange-50', border: 'border-orange-200', text: 'text-orange-800', icon: <AlertTriangle className="text-orange-500" size={18} /> },
  };
  const c = config[type];
  return (
    <div className={cn("fixed top-[15%] left-1/2 -translate-x-1/2 w-[90%] md:w-auto z-[100] flex items-center gap-3 px-4 py-3 rounded-2xl shadow-xl border animate-in fade-in zoom-in-95 justify-between", c.bg, c.border)}>
      <div className="flex items-center gap-3">
        {c.icon}
        <span className={cn("text-sm font-bold", c.text)}>{message}</span>
      </div>
      <button onClick={onClose} className={cn("p-1 rounded-full opacity-60 hover:opacity-100", c.text)}><X size={16} /></button>
    </div>
  );
}

export function Modal({ isOpen, onClose, title, children }: { isOpen: boolean, onClose: () => void, title: string, children: React.ReactNode }) {
  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 z-[100] flex items-start md:items-center justify-center bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full h-full md:h-auto md:max-h-[90vh] md:max-w-xl md:w-[50%] lg:w-[40%] xl:w-[35%] md:rounded-3xl shadow-2xl border border-sunset-primary/10 flex flex-col outline-none animate-in md:zoom-in-95 slide-in-from-bottom-full md:slide-in-from-bottom-0" tabIndex={-1}>
        <div className="flex items-center justify-between p-4 md:p-6 border-b border-sunset-primary/5 shrink-0 bg-white md:rounded-t-3xl pt-safe-top">
          <h3 className="font-bold text-sunset-dark text-lg md:text-xl">{title}</h3>
          <button onClick={onClose} className="p-2 rounded-full hover:bg-black/5 text-sunset-dark/40 hover:text-sunset-dark transition-colors"><X size={20} /></button>
        </div>
        <div className="p-4 md:p-6 overflow-y-auto flex-1">
          {children}
        </div>
      </div>
    </div>
  );
}

export * from "./ui/select";


"use client";

import { Card, Button, Input, Modal, Toast } from "@/components/ui";
import { User, Mail, Lock } from "lucide-react";
import { useState } from "react";

export default function ProfilePage() {
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  const [isEditProfile, setIsEditProfile] = useState(false);
  const [isChangePassword, setIsChangePassword] = useState(false);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleUpdate = () => {
    setIsEditProfile(false);
    showToast("Profile details updated successfully!");
  };

  const handlePasswordChange = () => {
    setIsChangePassword(false);
    showToast("Password changed securely.");
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 max-w-3xl mx-auto pb-4">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <Modal isOpen={isEditProfile} onClose={() => setIsEditProfile(false)} title="Edit Profile Details">
         <div className="space-y-4">
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Full Name</label><Input defaultValue="Alex Carter" /></div>
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Email Address</label><Input type="email" defaultValue="alex@example.com" /></div>
            <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
               <Button variant="ghost" onClick={() => setIsEditProfile(false)}>Cancel</Button>
               <Button onClick={handleUpdate}>Save Changes</Button>
            </div>
         </div>
      </Modal>

      <Modal isOpen={isChangePassword} onClose={() => setIsChangePassword(false)} title="Change Password">
         <div className="space-y-4">
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Current Password</label><Input type="password" placeholder="••••••••" /></div>
            <div className="border-t border-sunset-primary/5 py-1"></div>
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">New Password</label><Input type="password" placeholder="••••••••" /></div>
            <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Confirm New Password</label><Input type="password" placeholder="••••••••" /></div>
            <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
               <Button variant="ghost" onClick={() => setIsChangePassword(false)}>Cancel</Button>
               <Button onClick={handlePasswordChange}>Update Password</Button>
            </div>
         </div>
      </Modal>

      <header>
        <h1 className="text-2xl font-bold text-sunset-dark">Profile</h1>
        <p className="text-sm font-medium text-sunset-dark/60 mt-1">Manage your personal information and application settings.</p>
      </header>

      <Card className="flex flex-col md:flex-row items-center md:items-start gap-8 shadow-md shadow-black/5">
        <div className="w-28 h-28 rounded-[2rem] bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white flex items-center justify-center font-bold text-4xl shadow-lg shadow-sunset-primary/20 shrink-0">AC</div>
        
        <div className="flex-1 w-full space-y-6">
          <div className="space-y-4">
             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><User size={20}/></div>
                <div>
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Full Name</span>
                   <span className="font-black text-lg text-sunset-dark block">Alex Carter</span>
                </div>
             </div>
             
             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><Mail size={20}/></div>
                <div>
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Email Address</span>
                   <span className="font-black text-lg text-sunset-dark block">alex@example.com</span>
                </div>
             </div>

             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-black/5 flex items-center justify-center text-sunset-dark shrink-0"><Lock size={20}/></div>
                <div>
                   <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 block">Role</span>
                   <span className="font-black text-lg text-sunset-dark block">Basic</span>
                </div>
             </div>
          </div>
          
          <div className="border-t border-sunset-primary/10 pt-6 flex flex-col sm:flex-row gap-3">
            <Button onClick={() => setIsEditProfile(true)} className="flex-1"><User size={16} className="mr-2 inline" /> Edit Profile</Button>
            <Button variant="secondary" onClick={() => setIsChangePassword(true)} className="flex-1"><Lock size={16} className="mr-2 inline" /> Change Password</Button>
          </div>
        </div>
      </Card>
    </div>
  );
}

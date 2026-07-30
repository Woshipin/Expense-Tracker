"use client";

import { useState, useEffect } from "react";
import api from "@/lib/axios";

export function usePermission() {
  const [userPermissions, setUserPermissions] = useState<string[]>([]);
  const [userRole, setUserRole] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const loadUserPermissions = async () => {
      try {
        const res = await api.get("/me");
        if (isMounted && res.data) {
          setUserRole(Number(res.data.role));
          // 获取后端返回的打勾权限点数组
          setUserPermissions(res.data.permissions || []);
        }
      } catch (e) {
        if (isMounted) {
          setUserPermissions([]);
          setUserRole(null);
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };

    loadUserPermissions();

    // 🌟 全局实时通知监听器：权限组修改/保存时自动触发表单和侧边栏重新判定，无需刷新浏览器
    const handlePermissionsUpdated = () => {
      loadUserPermissions();
    };

    window.addEventListener("permissions-updated", handlePermissionsUpdated);

    return () => {
      isMounted = false;
      window.removeEventListener("permissions-updated", handlePermissionsUpdated);
    };
  }, []);

  /**
   * 🌟 核心权限校验逻辑
   */
  const can = (permissionCode: string): boolean => {
    // 规则 1：Super Admin (Role 0) 始终保底拥有 Permissions 页面管理权，防锁死
    if (userRole === 0 && permissionCode.startsWith("permissions.")) {
      return true;
    }

    // 规则 2：包含 '*' 通配符全开
    if (userPermissions.includes("*")) return true;

    // 规则 3：严谨匹配当前用户拥有的打勾节点
    return userPermissions.includes(permissionCode);
  };

  return { can, isLoading, userRole, userPermissions };
}
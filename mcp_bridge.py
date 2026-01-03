"""
MCP Bridge - 通信底层模块
负责与 REAPER 的文件通信系统交互
"""
import json
import time
import uuid
from pathlib import Path
from typing import Any, Dict

import os

class MCPBridge:
    """MCP 通信桥接器"""
    
    def __init__(self):
        # 基础路径设置为当前用户目录的 .orchestra 文件夹
        self.root = Path("~/.orchestra/").expanduser()
        self.inbox = self.root / "inbox"  # 使用 Path 的 / 运算符拼接路径
        self.outbox = self.root / "outbox"

        # 创建必要的目录（parents=True 确保父目录不存在时也能创建）
        self.inbox.mkdir(parents=True, exist_ok=True)
        self.outbox.mkdir(parents=True, exist_ok=True)
    
    def call_reaper(self, func_name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        向 REAPER 发送请求并等待响应
        
        Args:
            func_name: REAPER 侧函数名 (如: "track.create")
            params: 参数字典
            
        Returns:
            响应数据字典
        """
        # 生成唯一任务ID
        job_id = f"{int(time.time()*1000)}_agent_{uuid.uuid4().hex[:8]}"
        
        # 构建标准 JSON 信封
        envelope = {
            "meta": {
                "version": 1,
                "id": job_id,
                "ts_ms": int(time.time() * 1000)
            },
            "request": {
                "func": func_name,
                "param": params
            },
            "response": None
        }
        
        # 写入请求文件 (.part -> .json)
        req_file = self.inbox / f"{job_id}.json"
        part_file = self.inbox / f"{job_id}.json.part"
        
        try:
            with open(part_file, 'w', encoding='utf-8') as f:
                json.dump(envelope, f, ensure_ascii=False, indent=2)
            part_file.rename(req_file)
            
            # 轮询等待响应 (.reply.json)
            reply_file = self.outbox / f"{job_id}.reply.json"
            start_time = time.time()
            timeout = 10  # 10秒超时
            
            while time.time() - start_time < timeout:
                if reply_file.exists():
                    try:
                        with open(reply_file, 'r', encoding='utf-8') as f:
                            response_data = json.load(f)
                        
                        # 消费后删除响应文件
                        reply_file.unlink()
                        return response_data.get("response", {"ok": False, "error": {"code": "NO_RESPONSE"}})
                    except (json.JSONDecodeError, IOError) as e:
                        return {"ok": False, "error": {"code": "READ_ERROR", "message": str(e)}}
                
                time.sleep(0.1)
            
            # 超时处理
            return {"ok": False, "error": {"code": "TIMEOUT", "message": "REAPER no response"}}
            
        except IOError as e:
            return {"ok": False, "error": {"code": "IO_ERROR", "message": str(e)}}
    
    def create_json_envelope(self, func_name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        创建标准 JSON 信封（用于调试或手动操作）
        """
        return {
            "meta": {
                "version": 1,
                "id": f"manual_{int(time.time()*1000)}",
                "ts_ms": int(time.time() * 1000)
            },
            "request": {
                "func": func_name,
                "param": params
            },
            "response": None
        }


# 全局桥接器实例
bridge = MCPBridge()
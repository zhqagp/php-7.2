# PHP 7.2.34 Security Patch (CVE-2026-109618 & CVE-2026-109619 / PHP2Shell)

[![PHP Version](https://img.shields.io/badge/PHP-7.2.34-blue.svg)](https://www.php.net)
[![Security Status](https://img.shields.io/badge/Security-Patched-brightgreen.svg)](#vulnerabilities-fixed)
[![License](https://img.shields.io/badge/License-PHP--3.01-green.svg)](LICENSE)

[English](#english) | [中文说明](#中文说明)

---

<a name="english"></a>
## English

### Overview
PHP 7.2 officially reached **End-Of-Life (EOL)** on November 30, 2020. In 2026, severe critical Remote Code Execution (RCE) vulnerabilities nicknamed **PHP2Shell** were identified:
* **CVE-2026-109618** (GHSA-w8hw-w9fx-j79w): Core engine state corruption via bailout during out-of-memory (OOM) or interrupt (`longjmp`), leading to Heap Use-After-Free (UAF).
* **CVE-2026-109619** (GHSA-6wmf-4rv5-p3rp): Memory corruption during multipart/form-data upload processing with `session.upload_progress` tracking.

While the official PHP upstream team provided backported patch branches for PHP 7.4, 8.0, and 8.1 (`PHP-7.4-CVE-2026-109618-109619`), **no official fix was released for PHP 7.2**.

This repository provides a **fully tested, unofficial backport of the official upstream fixes to PHP 7.2.34**, allowing legacy production services that cannot be immediately migrated to PHP 7.4/8.x to remain protected against automated RCE exploitation.

---

### How to Use

#### Method 1: Apply Patch Directly (Fastest)
If you already build PHP 7.2 from source, download and apply the standalone patch file ([php-7.2-cve-2026-109618-109619.patch](php-7.2-cve-2026-109618-109619.patch)):
```bash
curl -SL https://raw.githubusercontent.com/zhqagp/php-7.2/main/php-7.2-cve-2026-109618-109619.patch -o php72-cve.patch
patch -p1 < php72-cve.patch
php Zend/zend_vm_gen.php
```

#### Method 2: Build Docker Image (Out-of-the-box)
This repository includes a ready-to-use [Dockerfile](Dockerfile) based on Alpine Linux:
```bash
git clone https://github.com/zhqagp/php-7.2.git
cd php-7.2
docker build -t php:7.2-fpm-patched .
```

#### Method 3: Emergency Workaround (If you cannot recompile immediately)
If you cannot recompile PHP immediately, mitigate the primary public exploitation vector by disabling `session.upload_progress` in your `php.ini`:
```ini
session.upload_progress.enabled = Off
expose_php = Off
```

---

<a name="中文说明"></a>
## 中文说明

### 项目背景
PHP 7.2 官方已于 2020 年 11 月停止所有安全支持（EOL）。2026 年曝光的 **PHP2Shell** 漏洞引发了大规模自动化挂马攻击：
* **CVE-2026-109618**：内存不足（OOM）或 bailout 异常中断时的堆状态破坏与 Use-After-Free（UAF）远程代码执行。
* **CVE-2026-109619**：基于 multipart/form-data 文件上传与 `session.upload_progress` 触发的内存破坏。

官方开源团队仅为仍在维护周期或较新的 7.4、8.0、8.1 分支提供了补丁分支，但**未提供 PHP 7.2 的修复代码**。许多传统企业级老旧系统因语法差异（如 `mcrypt_*`、花括号数组语法等）无法在一夜之间升级到 PHP 8。

本仓库将官方针对该漏洞的修复代码**完整移植（Backport）至 PHP 7.2.34**，已重新生成底层虚拟机指令集并验证编译通过。

---

### 使用方式

#### 方式一：独立补丁文件（适用于已有编译脚本）
直接下载仓库提供的独立补丁文件 [php-7.2-cve-2026-109618-109619.patch](php-7.2-cve-2026-109618-109619.patch)：
```bash
wget https://raw.githubusercontent.com/zhqagp/php-7.2/main/php-7.2-cve-2026-109618-109619.patch
patch -p1 < php-7.2-cve-2026-109618-109619.patch
```

#### 方式二：Docker 一键构建镜像
仓库根目录内置了开箱即用的 [Dockerfile](Dockerfile)：
```bash
git clone https://github.com/zhqagp/php-7.2.git
cd php-7.2
docker build -t php:7.2-fpm-alpine .
```

#### 方式三：临时缓解措施（无法立刻重新编译时）
在 `php.ini` 中追加以下配置，可阻断公网大部分自动化扫描工具：
```ini
session.upload_progress.enabled = Off
expose_php = Off
```

---

### 修复的核心文件列表 (15 Files)
* `main/rfc1867.c`：限制 multipart 头大小与分块数量，防止超大异常报文触发内存溢出
* `ext/session/session.c`：规避上传进度跟踪的回调钩子
* `Zend/zend_alloc.c` & `Zend/zend_alloc.h`：引入安全错误退出函数 `zend_mm_safe_error_ex`
* `Zend/zend_execute_API.c` & `main/SAPI.c`：彻底重置并清空异常请求后的指针与错误处理器
* `Zend/zend_vm_def.h` & `Zend/zend_vm_execute.h`：修复字符串拼接（CONCAT）整数溢出
* `Zend/zend_API.h` & `main/php_variables.c`：单例哈希表初始化优化
* `Zend/zend_hash.c`、`Zend/zend_llist.c`、`Zend/zend_multiply.h`、`Zend/zend_strtod.c`、`main/main.c`

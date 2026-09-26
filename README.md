
## 说明

用于OpenWrt的 mihomo LuCI 轻量管理面板，支持YAML配置编辑、上传下载配置、自定义下载核心、更新配置、清理缓存与打开Web控制面板等。

<img width="1836" height="1287" alt="1" src="https://github.com/user-attachments/assets/016f9dc2-7aea-4b6a-bc0f-15b940d845f2" />

<img width="1827" height="1303" alt="2" src="https://github.com/user-attachments/assets/2c48eae7-777a-4fce-bcbd-5dd334acf9d6" />

## 功能

- 查看 mihomo 版本、运行状态、配置路径。
- 启动、停止、重启服务，设置开机启动。
- 粘贴、编辑和校验 YAML 配置。
- 支持在线下载配置及上传本地配置文件。
- 支持自定义核心地址下载更新内核。
- 清理 `cache.db` 运行缓存。
- 一键更新配置及打开Web控制面板。

## 安装

本面板依赖 mihomo 内核包，你也可以在面板「配置」页通过下载核心地址更新内核，或手动放置到 `/usr/bin/mihomo`。

```sh
# opkg（IPK 包，当前版本 1.2-3）
opkg install /tmp/luci-app-meta_1.2-3_all.ipk   # 或你上传的 /tmp/upload.ipk

# APK（当前版本 1.2-r3）
apk add --allow-untrusted /tmp/luci-app-meta-1.2-r3.apk

/etc/init.d/rpcd restart
```

发布的 APK 未签名，安装时需要 `--allow-untrusted`。运行依赖为 `luci-base`、`rpcd`、`jshn`、`jsonfilter`、`curl` mihomo核心需要对应架构的版本，否则架构不兼容而启动失败。

若需更新或替换内核，另有两种方式：

- **面板下载**：进入 **配置** 标签页，在「下载核心地址」填入 mihomo 二进制（或 `.gz`）直链，点「下载核心」。后端用 curl/wget 下载，自动解压 `.gz`、校验 `mihomo -v` 可用后写入 `/usr/bin/mihomo` 并重启服务。
- **手动放置**：将 mihomo 可执行文件放到 `/usr/bin/mihomo` 并 `chmod +x`。

内核就位后，面板自带的 `/etc/init.d/mihomo` 即可启停服务。

## mihomo 服务配置

面板默认使用以下路径：

```text
/usr/bin/mihomo                  (内核，由 mihomo-meta 包提供，也可自行下载/放置)
/etc/init.d/mihomo               (procd 服务，由本面板提供)
/etc/mihomo/core.sh              (面板共享后端脚本，由 rpcd 插件与后台 worker 载入)
/usr/libexec/rpcd/luci.mihomo    (rpcd 插件)
/usr/libexec/mihomo-panel-worker (后台任务 worker)
/etc/config/mihomo               (UCI，可选，缺失时按默认值处理并按需自动创建 main 段)
/etc/mihomo/config.yaml          (工作目录与主配置)
```

> 面板共享后端脚本 `core.sh` 随包安装在 `/etc/mihomo/` 下，与工作目录、主配置同处一处，便于集中管理；rpcd 插件与后台 worker 均从 `/etc/mihomo/core.sh` 载入。该文件由软件包管理，卸载时移除，不影响你在同目录下的 `config.yaml`、`cache.db` 等数据。

> 本面板随包安装 `/etc/init.d/mihomo` 这个 procd 启动脚本，服务名与实例名均为 `mihomo`，因此面板能通过 procd/ubus 启停并查询状态。它读取 UCI 的 `enabled`/`conffile`/`workdir` 运行 `mihomo -d <workdir> -f <conffile>`，并把 stdout/stderr 送往系统日志（`logread -e mihomo` 可读）。像 `mihomo-meta` 这种只装二进制、不带 init 的核心包正好与之配合。若你的内核包本身已提供 `/etc/init.d/mihomo`，安装时会发生文件冲突，请二选一。

`/etc/config/mihomo` 示例：

```uci
config mihomo 'main'
        option enabled '1'
        option conffile '/etc/mihomo/config.yaml'
        option workdir '/etc/mihomo'
```

| 选项         | 用途                                               |
| ------------ | -------------------------------------------------- |
| `enabled`    | 服务启动开关，启动、重启、应用或开启自启时设为 `1` |
| `conffile`   | 面板直接读写的 YAML 配置文件，使用绝对路径，默认 `/etc/mihomo/config.yaml` |
| `workdir`    | mihomo 工作目录（`-d`），默认 `/etc/mihomo`        |
| `user`       | 面板用于指定新建配置文件所有者的用户选项           |

本面板不随包安装 `/etc/config/mihomo`，以免升级时覆盖用户设置。若该文件或 `main` 段不存在，`conffile` 与 `workdir` 使用上表默认值；执行开机启动、启动或应用时后端会自动创建 `config mihomo 'main'` 段。未配置 `user` 时，面板按 root 处理新建配置文件的所有者。

配置文件的父目录需要已存在，配置文件应为普通文件。保存现有文件时保留其所有者和权限，新建文件的权限为 0600。

**开机启动**启用 init 服务启动链接，并将 `enabled` 设为 `1`；取消勾选只禁用启动链接。

**停止**停止当前服务，不修改开机启动设置。停止命令成功返回后，等待确认进程退出。

配置路径或工作目录异常时，仍可停止服务、查看系统日志。只读账号可以查看状态和复制配置、查看日志；编辑、校验和服务控制均不可用。

## 配置使用

| 操作        | 行为                                                     |
| ----------- | -------------------------------------------------------- |
| 校验配置    | 通过临时文件校验编辑器内容，不保存、不重启               |
| 保存并应用  | 保存、校验，通过后重启服务                               |
| 重载配置    | 从 `conffile` 重新读取内容；有未保存修改时先确认是否放弃 |

配置大小上限为 **128 KiB**，按 UTF-8 字节数计算。mihomo 使用 YAML，面板不提供浏览器端“格式化”，避免引入额外依赖；请直接编辑标准 YAML。

校验使用已安装的 mihomo 内核及服务工作目录。“校验”传入临时文件路径，完成后清理；“保存并应用”传入正式配置路径：

```sh
mihomo -t -d <workdir> -f <待校验文件>
```

单独校验不会改动正式配置或服务状态。“保存并应用”先保存再校验；校验失败时显示内核错误，已保存的文件保留，服务不重启。修改错误后可再次保存并应用。

保存前会检查文件版本。如果其他窗口或 SSH 已修改文件，页面会提示重新加载，避免覆盖外部修改。

### 配置写入

配置直接写入 UCI 的 `conffile` 路径，采用同目录临时文件加原子替换，完成后清理临时文件。“下载配置”与“上传配置”按无条件覆盖写入（不做版本比对）。

保存并应用后的启动检查要求服务 PID 在约 3 秒内保持存活且不变。启动失败时显示错误，已保存配置保留，需要修改后重新应用。

## 清理缓存

**概览 → 维护服务 → 清理缓存** 会停止服务并删除工作目录内的 `cache.db`（mihomo 在启用 `profile.store-selected` / `store-fake-ip` 时生成），随后重新启动服务。

仅支持无符号链接的专用工作目录：`/etc/mihomo`、`/usr/share/mihomo`、`/var/lib/mihomo`、`/tmp/mihomo`。缓存安全检查使用系统自带的 `ls` 和 `/proc/self/mountinfo` 获取硬链接数及文件身份，无需安装 `stat` 或 `coreutils-stat`。新缓存由 mihomo 启动时生成；启动失败会显示错误并尝试停止服务，旧缓存无法恢复。

## 打开面板

**概览 → 维护服务 → 打开面板** 从编辑器中的 YAML 解析 `external-controller` 端口与 `secret`，在新标签打开 mihomo 内置的 Web 控制面板 `http://<路由器地址>:<端口>/ui/`。需要 YAML 中配置 `external-controller`（含端口）与可选的 `external-ui`/`secret`。

## 日志

日志页通过 `logread` 读取 mihomo 系统日志，显示最近 300 行，最多 32 KiB。进入日志页立即读取一次，停留在日志页时每 2 秒更新；可通过右上角 LuCI 刷新开关暂停或恢复自动更新。

- 系统日志是否收集 mihomo 输出，取决于设备上的服务启动脚本。
- YAML 中设置 `log-level: silent` 时，页面显示日志关闭提示。

面板显示日志时过滤 ANSI 颜色码。

## GitHub Actions 打包发布

工作流：[release.yml](.github/workflows/release.yml)。在 Ubuntu 上直接生成供 OpenWrt 使用的 APK v3 与 IPK 包，无需下载 SDK 或选择 CPU 架构。

1. 将项目提交到 GitHub，保持 `Makefile`、`htdocs`、`root` 和 `.github` 位于仓库根目录。
2. 进入 **Actions → Release → Run workflow**。
3. 选择构建分支，填写新标签（例如 `v1.2`，留空默认 `v1.2`）。
4. 按需勾选 `prerelease`，然后运行工作流。

发布 Tag 固定为 `meta`。安装包为 `noarch`，面板自身不含架构相关的二进制文件；mihomo 内核和其他运行依赖由设备的软件源提供。

## 从源码构建

在 Linux 上使用与目标固件匹配的 OpenWrt SDK 或源码树，将项目放到 `package/luci-app-meta`：

```sh
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig      # 选择 LuCI → Applications → luci-app-meta
make package/luci-app-meta/compile V=s
```

也可通过 `LUCI_META_VERSION` 指定源码构建的版本号。

## 故障排查

- **页面没有出现**：重启 `rpcd` 后重新登录 LuCI。
- **配置校验失败**：根据页面显示的 mihomo 错误修改 YAML，确认 `conffile`、`workdir` 及引用的 geo/规则文件路径。
- **未检测到内核 / 无法启动**：确认已通过「配置」页下载核心或手动放置了 `/usr/bin/mihomo` 且可执行（`mihomo -v` 能输出版本）。
- **操作长时间未结束**：检查 `/tmp/mihomo-panel/lock/pid` 对应的后台进程。确认进程已退出后，再处理锁和临时任务数据。

临时任务数据位于 `/tmp/mihomo-panel/`，设备重启后会清除。

## 参考

- [mihomo 项目](https://github.com/MetaCubeX/mihomo)
- [mihomo Wiki / 配置文档](https://wiki.metacubex.one/)
- [LuCI 应用示例](https://github.com/openwrt/luci/tree/master/applications/luci-app-example)

## 许可证

[MIT](LICENSE)

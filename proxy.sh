#!/system/bin/sh

# 来源：https://bulianglin.com/archives/android-gateway.html

tun='tun0'  # 虚拟接口名称
dev='wlan0' # 物理接口名称，eth0、wlan0
interval=3  # 检测网络状态间隔(秒)
pref=18000  # 路由策略优先级

# 开启IP转发功能
sysctl -w net.ipv4.ip_forward=1

# 清除filter表转发链规则
iptables -F FORWARD

# 添加NAT转换，部分VPN需要此设置
iptables -t nat -A tetherctrl_nat_POSTROUTING -o $tun -j MASQUERADE

# 添加路由策略
ip rule add from all table main pref $pref
ip rule add from all iif $dev table $tun pref $(expr $pref - 1)

contain="from all iif $dev lookup $tun"

while true ;do
    if [[ $(ip rule) != *$contain* ]]; then
            if [[ $(ip ad|awk '/state UP/ {print $2}') != *$dev* ]]; then
                echo -e "[$(date "+%H:%M:%S")]dev has been lost."
            else
                ip rule add from all iif $dev table $tun pref $(expr $pref - 1)
                echo -e "[$(date "+%H:%M:%S")]network changed, reset the routing policy."
            fi
    fi
    sleep $interval
done

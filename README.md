# Home Mediacenter

Ready-to-use home mediacenter setup. Included [Jellyfin](https://jellyfin.org/), [Immich](https://immich.app/), [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/) and [Transmission](https://transmissionbt.com/).

Idea is to make setup as simple as possible, and have reliable home mediacenter with most common services.

## Hardware setup

Performance/cost decision first. For media storage we should use HDD. For databases, config etc. - SSD.

So hardware setup should look like this:

- server - Raspberry PI 5 or any other custom build with linux
- fast storage - any SSD
- media storage - HDD (you are welcome to introduce raid here)

### Step 1. Configure mount points for SSD and HDD.

```shell
mkdir -p /mnt/{SSD,HDD}
```

### Step 2. Configure mounting

Important filesystem decision here. Our SSD will be used only by our mediacenter for databases, caches etc. We safely can use EXT4 filesystem for it.
But for HDD situation is different. At any time we can decide to configure SMB share for it, or access from any
device like smart tv, Windows, etc.. So for this drive we should use some widely supported filesystem, like NTFS.

Configure NTFS support:

```shell
sudo apt install ntfs-3g
```

Next, we will use fstab to mount drives. Find UUID's of your drives, and save them somewhere.

```shell
lsblk -f
```

or

```shell
blkid
```

Next, edit fstab:

```shell
nano /etc/fstab
```

and add next records

```bash
UUID=your-ssd-uuid  /mnt/SSD  ext4  defaults,noatime,nofail  0  2
UUID=your-hdd-uuid  /mnt/HDD  ntfs-3g  defaults,nofail,uid=1000,gid=1000,dmask=027,fmask=137,x-systemd.automount  0  0
```

Keep in mind. We want to idle our HDD if it don't used. So install hdparm

```shell
sudo apt install hdparm
```

and configure idle time

```shell
sudo nano /etc/hdparm.conf
```

add next section in the end of file (after examples)

```bash
/dev/sdb {
    spindown_time = 120
}
```

where /dev/sdb is your HDD device (it can be for example /dev/sda1 etc.).

*\*Spindown time measured in 5 seconds. So 120 mean 120\*5 = 600, 10 minutes of inactivity*

and reboot our server

```shell
sudo reboot
```

Now we have configued hardware setup with drives mounted in

- /mnt/HDD
- /mnt/SSD

respectfully.

If not installed, install docker. You can use official [manual](https://docs.docker.com/engine/install/) or run commands:

```shell
curl -fsSL https://get.docker.com | sudo sh

sudo usermod -aG docker $USER

exit
```

and then login to server again.

### Step 2. Server setup

```shell
cd ~/

git clone https://github.com/a-kryvenko/mediacenter.git

docker compose up -d
```

Mediacenter is ready. Now in you /etc/hosts or in router admin panel declare routes to services:

- 192.168.0.254 mediacenter.lan
- 192.168.0.254 immich.mediacenter.lan
- 192.168.0.254 jellyfinmediacenter.lan
- 192.168.0.254 radarr.mediacenter.lan
- 192.168.0.254 sonarr.mediacenter.lan
- 192.168.0.254 transmission.mediacenter.lan

where 192.168.0.254 is IP address of you server. I strongly recommend to make this IP address
permanently binded to your sever in router admin panel. Also, if possible, declare this hosts records
in router admin panel to avoid re-write them on each device.

 # Extras

 Some tv's not support modern video codecs. Jellyfin gently try to reencode them on-the-fly during playback. On high-end servers it's ok, but on Raspberry PI (even on 5) that's painfull. So we should schedule crontab task that will run each day, scan video files, and if needed reencode all of them into **h264**. 

 In extras folder is ready-to-use scripts for CPU encoding, and encoding with hardware acceleration on Apple M1 CPU.

 Because reencoding is heavy task, you are welcome to tweak this scripts to make them as performace as possible on your server.
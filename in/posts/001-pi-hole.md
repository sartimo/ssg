---
title: Setting up a Pi-hole on my Raspberry Pi
date: 2021-05-30
author: Michael Zeevi
description: asasasasassa
keywords:
- pi-hole
- raspberry-pi
- dns 
lang: en-us
---

## Intro
Today's personal endeavor was setting up a [Pi-hole](https://pi-hole.net/) to block unwanted content for all devices connected to my home network.

## How it works
For anybody unfamiliar, I'll briefly explain how a Pi-hole works:

The Pi-hole acts as a _sole_ (single) local DNS server, configured with a blacklist of domains which are known for serving ads and other unwanted content (such as trackers). This way, whenever an application (such as a web browser, or even a game on one's smartphone) needs to fetch external content, then the process starts by attempting to resolve the serving domain; if the domain is in the Pi-hole's blacklist then the Pi-hole _doesn't_ return the content.
The importance of a Pi-hole being the _sole_ DNS server on the network is so that when queries for unwanted content are blocked, there should _not_ be an alternative DNS server to fall-back on, which would succeed at resolving the queries for unwanted content.

## Deployment
I deployed _my_ Pi-hole server as a Docker container, running on a [Raspberry Pi 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/). Specific instructions about this can be found on the [Pi-hole page at DockerHub](https://hub.docker.com/r/pihole/pihole). The `docker-compose.yaml` file contains:
```
version: "3"
services:
  pihole:
    container_name: pihole
    hostname: 'pi.hole'
    image: pihole/pihole:v5.8.1-armhf-buster
    network_mode: host
    environment:
      TZ: 'Israel'
      PIHOLE_DNS_: '1.1.1.1;1.0.0.1'
      DNSSEC: 'true'
      VIRTUAL_HOST: 'pi.hole'
    volumes:
      - './etc-pihole/:/etc/pihole/'
      - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

## Router configuration (DHCP and DNS)
In my router I reserved the Raspberry Pi's IP address' DHCP lease (so that it wouldn't have the chance to change in case of a restart, etc.), and configured the router's DNS nameserver to use the Raspberry Pi, which serves the Pi-hole. Note that the _Secondary DNS_ field - which must remain empty!

![Router DHCP reservation lease](res/pi-hole/router-dhcp-reservation-lease.png)

![Router DNS configuration](res/pi-hole/router-dns-config.png)

## Pi-hole configuration (local DNS record)
In the Pi-hole I optionally chose to configure a local DNS record to map the domain name [pi.hole](http://pi.hole/) to its [reserved] IP address. This allows me to access the Pi-hole's front end dashboard (which it exposes automatically) via a comfortable domain name, instead of its IP address.

![Pi-hole address bar](res/pi-hole/address-bar.png)

![Pi-hole dashboard](res/pi-hole/dashboard.png)

## Conclusion
In conclusion, this is a neat project which involves a nice handful of network and internet theory, bundled into an elegant solution for an everyday problem.

There is one major caveat with this solution, in regards of blocking ads: it doesn't work for ads in YouTube videos. The reason for this is because the ads are served from the _same_ domains as the actual video content. Therefore, if one's a frequent consumer of YouTube, then they should consider using a browser based ad-blocker plugin in addition to a Pi-hole.

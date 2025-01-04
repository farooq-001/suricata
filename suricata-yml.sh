#!/bin/bash

# Echo the entered SPAN_PORT value
echo "Entered SPAN_PORT value: $SPAN_PORT"

# Create or overwrite the docker-compose.yml file
cat <<EOF | tee /opt/sensor/conf/etc/capture/blusapphire.yaml

%YAML 1.1
---
max-pending-packets: 2048

host-mode: sniffer-only

pid-file: /var/run/blu_paf.pid

#default-packet-size: 1514

default-log-dir: /var/log/capture/

unix-command:
  enabled: no
  #filename: custom.socket

# global stats configuration
stats:
  enabled: yes
  interval: 10

# Configure the type of alert (and other) logging you would like.
outputs:
  # Extensible Event Format (nicknamed EVE) event log in JSON format

  - eve-log:
      enabled: yes
      filetype: regular
      filename: alerts-%Y-%m-%dT%H%M%S.json
      level: Critical 
      rotate-interval: 3600s
# Community Flow ID
    # Adds a 'community_id' field to EVE records. These are meant to give
    # a records a predictable flow id that can be used to match records to
    # output of other tools such as Bro.
    #
    # Takes a 'seed' that needs to be same across sensors and tools
    # to make the id less predictable.

    # enable/disable the community id feature.
      community-id: true
    # Seed value for the ID output. Valid values are 0-65535.
      community-id-seed: 0

      types:
        - alert

  - pcap-log: 
      enabled:  no 
      filename: log.pcap 

      # Limit in MB. 
      limit: 256 

      mode: normal # "normal" (default) or sguil. 
      #sguil-base-dir: /var/log/capture/pcaps/   

  # Stats.log contains data from various counters of the capture engine.
  - stats:
      enabled: no
      filename: stats.log


  # output module to store extracted files to disk
  - file-store:
      enabled: no #yes      # set to yes to enable
      log-dir: files    # directory to store the files
      force-magic: yes  # force logging magic on all stored files
      force-hash: [md5] # force logging of md5 checksums
      waldo: file.waldo # waldo file to store the file_id across runs

  # output module to log files tracked in a easily parsable json format
  - file-log:
      enabled: no
      filename: files-json.log 
      #append: yes
      filetype: regular    # 'regular', 'unix_stream' or 'unix_dgram'
      force-magic: yes     # force logging magic on all logged files
      force-hash: [md5]    # force logging of md5 checksums

  # Log TCP data after stream normalization
  # 2 types: file or dir. File logs into a single logfile. Dir creates
  # 2 files per TCP session and stores the raw TCP data into them.
  # Using 'both' will enable both file and dir modes.
  #
  # Note: limited by stream.depth
  - tcp-data:
      enabled: no #yes
      type: dir
      filename: tcp-data.log

# Magic file. The extension .mgc is added to the value here.
#magic-file: /usr/share/file/magic
magic-file: /usr/share/misc/magic


# netmap support
#netmap:
# - interface:$SPAN_PORT
   #   threads: auto
# - interface: default
af-packet:
  - interface: $SPAN_PORT
    threads: auto
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
    use-mmap: yes
    tpacket-v3: yes
    block-size: 73728
  - interface: default

legacy:
  uricontent: enabled


detect-engine:
  - profile: medium
  - custom-values:
      toclient-src-groups: 2
      toclient-dst-groups: 2
      toclient-sp-groups: 2
      toclient-dp-groups: 3
      toserver-src-groups: 2
      toserver-dst-groups: 4
      toserver-sp-groups: 2
      toserver-dp-groups: 25
  - sgh-mpm-context: auto
  - inspection-recursion-limit: 3000

threading:
  # On some cpu's/architectures it is beneficial to tie individual threads
  # to specific CPU's/CPU cores. In this case all threads are tied to CPU0,
  # and each extra CPU/core has one "detect" thread.
  #
  # On Intel Core2 and Nehalem CPU's enabling this will degrade performance.
  #
  set-cpu-affinity: no
  # Tune cpu affinity of threads. Each family of threads can be bound
  # on specific CPUs.
  cpu-affinity:
    - management-cpu-set:
        cpu: [ 0 ]  # include only these cpus in affinity settings
    - receive-cpu-set:
        cpu: [ 0 ]  # include only these cpus in affinity settings
    - decode-cpu-set:
        cpu: [ 0, 1 ]
        mode: "balanced"
    - stream-cpu-set:
        cpu: [ "0-1" ]
    - detect-cpu-set:
        cpu: [ "all" ]
        mode: "exclusive" # run detect threads in these cpus
        # Use explicitely 3 threads and don't compute number by using
        # detect-thread-ratio variable:
        # threads: 3
        prio:
          low: [ 0 ]
          medium: [ "1-2" ]
          high: [ 3 ]
          default: "medium"
    - verdict-cpu-set:
        cpu: [ 0 ]
        prio:
          default: "high"
    - reject-cpu-set:
        cpu: [ 0 ]
        prio:
          default: "low"
    - output-cpu-set:
        cpu: [ "all" ]
        prio:
           default: "medium"

  detect-thread-ratio: 1.5


mpm-algo: ac


pattern-matcher:
  - b2g:
      search-algo: B2gSearchBNDMq
      hash-size: low
      bf-size: medium
  - b3g:
      search-algo: B3gSearchBNDMq
      hash-size: low
      bf-size: medium
  - wumanber:
      hash-size: low
      bf-size: medium

# Defrag settings:

defrag:
  memcap: 32mb
  hash-size: 65536
  trackers: 65535 # number of defragmented flows to follow
  max-frags: 65535 # number of fragments to keep (higher than trackers)
  prealloc: yes
  timeout: 60
  
# Flow settings:
flow:
  memcap: 32mb
  hash-size: 65536
  prealloc: 10000
  emergency-recovery: 30

vlan:
  use-for-tracking: true


flow-timeouts:
  default:
    new: 30
    established: 300
    closed: 0
    emergency-new: 10
    emergency-established: 100
    emergency-closed: 0
  tcp:
    new: 60
    established: 3600
    closed: 120
    emergency-new: 10
    emergency-established: 300
    emergency-closed: 20
  udp:
    new: 30
    established: 300
    emergency-new: 10
    emergency-established: 100
  icmp:
    new: 30
    established: 300
    emergency-new: 10
    emergency-established: 100

# Stream engine settings. 
stream:
  memcap: 4gb
  checksum-validation: yes      # reject wrong csums
  inline: auto                  # auto will use inline mode in IPS mode, yes or no set it statically
  reassembly:
    memcap: 6gb
    depth: 5mb                  # reassemble 1mb into a stream
    toserver-chunk-size: 2560
    toclient-chunk-size: 2560
    randomize-chunk-size: yes


# Host table:
#
# Host table is used by tagging and per host thresholding subsystems.
#
host:
  hash-size: 4096
  prealloc: 1000
  memcap: 16777216

# Logging configuration.

logging:

  default-log-level: notice
  default-output-filter:

  outputs:
  - console:
      enabled: no
  - file:
      enabled: yes
      filename: /var/log/capture.log

pcap-file:
  checksum-checks: auto


# Set the default rule path here to search for the files.
# if not set, it will look at the current working dir
default-rule-path: /opt/sensor/conf/etc/capture/rules
rule-files:
 - botcc.portgrouped.rules
 - botcc.rules 
 - ciarmy.rules
 - compromised.rules
 - drop.rules
 - dshield.rules
 - activex.rules
 - attack_response.rules
 - chat.rules
 - current_events.rules
 - dns.rules
 - dos.rules
 - exploit.rules
 - ftp.rules
# - games.rules
 - imap.rules
 - inappropriate.rules
 - malware.rules
 - misc.rules
 - mobile_malware.rules
 - netbios.rules
 - p2p.rules
 - policy.rules
 - pop3.rules
 - rpc.rules
# - scada.rules
# - scada_special.rules
 - scan.rules
 - shellcode.rules
 - smtp.rules
 - snmp.rules
 - sql.rules
 - telnet.rules
 - tftp.rules
 - trojan.rules
 - user_agents.rules
 - voip.rules
 - web_client.rules
 - web_server.rules
 - worm.rules
 - tor.rules
# - decoder-events.rules # available in sources under rules dir
# - stream-events.rules  # available in sources under rules dir
# - http-events.rules    # available in sources under rules dir
# - smtp-events.rules    # available in sources under rules dir
# - dns-events.rules     # available in sources under rules dir
# - tls-events.rules     # available in sources under rules dir
# - modbus-events.rules  # available in sources under rules dir
# - app-layer-events.rules  # available in sources under rules dir
 - files.rules
# - noalert.rules

classification-file: /opt/sensor/conf/etc/capture/rules/classification.config
reference-config-file: /opt/sensor/conf/etc/capture/rules/reference.config

# Holds variables that would be used by the engine.
vars:

  # Holds the address group vars that would be passed in a Signature.
  # These would be retrieved during the Signature address parsing stage.
  address-groups:

    HOME_NET: "[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]"

    EXTERNAL_NET: "!$HOME_NET"

    HTTP_SERVERS: "$HOME_NET"

    SMTP_SERVERS: "$HOME_NET"

    SQL_SERVERS: "$HOME_NET"

    DNS_SERVERS: "$HOME_NET"

    TELNET_SERVERS: "$HOME_NET"

    AIM_SERVERS: "$EXTERNAL_NET"

    DNP3_SERVER: "$HOME_NET"

    DNP3_CLIENT: "$HOME_NET"

    MODBUS_CLIENT: "$HOME_NET"

    MODBUS_SERVER: "$HOME_NET"

    ENIP_CLIENT: "$HOME_NET"

    ENIP_SERVER: "$HOME_NET"

  # Holds the port group vars that would be passed in a Signature.
  # These would be retrieved during the Signature port parsing stage.
  port-groups:

    HTTP_PORTS: "80"

    SHELLCODE_PORTS: "!80"

    ORACLE_PORTS: 1521

    SSH_PORTS: 22

    DNP3_PORTS: 20000

    MODBUS_PORTS: 502


# Host specific policies for defragmentation and TCP stream
# reassembly.  The host OS lookup is done using a radix tree, just
# like a routing table so the most specific entry matches.
host-os-policy:
  # Make the default policy windows.
  windows: [0.0.0.0/0]
  bsd: []
  bsd-right: []
  old-linux: []
  linux: [10.0.0.0/8, 192.168.1.100, "8762:2352:6241:7245:E000:0000:0000:0000"]
  old-solaris: []
  solaris: ["::1"]
  hpux10: []
  hpux11: []
  irix: []
  macos: []
  vista: []
  windows2k3: []


# Limit for the maximum number of asn1 frames to decode (default 256)
asn1-max-frames: 256

engine-analysis:
  # enables printing reports for fast-pattern for every rule.
  rules-fast-pattern: yes
  # enables printing reports for each rule
  rules: yes

#recursion and match limits for PCRE where supported
pcre:
  match-limit: 3500
  match-limit-recursion: 1500

# app-layer details. The protocols section details each protocol.
app-layer:
  protocols:
    tls:
      enabled: yes
      detection-ports:
        dp: 443

      #no-reassemble: yes
    dcerpc:
      enabled: yes
    ftp:
      enabled: yes
    ssh:
      enabled: yes
    smtp:
      enabled: yes
      # Configure SMTP-MIME Decoder
      mime:
        # Decode MIME messages from SMTP transactions
        # (may be resource intensive)
        # This field supercedes all others because it turns the entire
        # process on or off
        decode-mime: yes

        # Decode MIME entity bodies (ie. base64, quoted-printable, etc.)
        decode-base64: yes
        decode-quoted-printable: yes

        # Maximum bytes per header data value stored in the data structure
        # (default is 2000)
        header-value-depth: 2000

        # Extract URLs and save in state data structure
        extract-urls: yes
      # Configure inspected-tracker for file_data keyword
      inspected-tracker:
        content-limit: 1000
        content-inspect-min-size: 1000
        content-inspect-window: 1000
    imap:
      enabled: detection-only
    msn:
      enabled: detection-only
    smb:
      enabled: yes
      detection-ports:
        dp: 139
    modbus:
      enabled: yes
      detection-ports:
        dp: 502
    #smb2:
    #  enabled: yes
    dns:
      # memcaps. Globally and per flow/state.
      #global-memcap: 16mb
      #state-memcap: 512kb
      tcp:
        enabled: yes
        detection-ports:
          dp: 53
      udp:
        enabled: yes
        detection-ports:
          dp: 53
    http:
      enabled: yes
      memcap: 4gb
      libhtp:
         default-config:
           personality: IDS

           # Can be specified in kb, mb, gb.  Just a number indicates
           # it's in bytes.
           request-body-limit: 0 #3072
           response-body-limit: 0 #3072

           # inspection limits
           request-body-minimal-inspect-size: 32kb
           request-body-inspect-window: 4kb
           response-body-minimal-inspect-size: 32kb
           response-body-inspect-window: 4kb
           #randomize-inspection-range: 10

           # decoding
           double-decode-path: no
           double-decode-query: no
           
         server-config:

# Core dump configuration. 
coredump:
  max-dump: unlimited

EOF

# Notify the user
echo "Configuration successfully written to /opt/sensor/conf/etc/capture/blusapphire.yaml"

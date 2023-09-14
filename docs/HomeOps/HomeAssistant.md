# Home Assistant

Home Assistant powers our house. At some point I'll update this page with more
documentation on all the little IoT devices and automations that we've set up,
but for now I'll just include a few examples that people often ask me about.


## Linux Desktop PC Shutdown

I run [hacompanion](https://github.com/tobias-kuendig/hacompanion) on my linux desktop PC, and it is really handy for sending sensor data to HA. But one thing I use frequently isn't covered by hacompanion, and that is the ability to remotely shutdown my PC.

I want to be able to poweroff my PC manually and automatically to conserve power usage.

Implementing this was surprisingly simple.

1. A simple python program that runs as a systemd service. It listens on a port for a shutdown command (with a pre shared token for auth).
2. An HA script to perform the shutdown
3. Some automations to run the HA script automatically.

You can find the [script here in my NixOS config](https://github.com/Ramblurr/nixcfg/blob/main/modules/desktop/services/shutdown.py). In the same directory is the NixOS config for setting up a systemd service, that looks something like this (with all the Nix stuff removed):

```
[Unit]
After=network.target network-online.target
Description=HA Shutdown Service

[Service]
EnvironmentFile=/run/secrets/HA_SHUTDOWN_TOKEN
ExecStart=python -u /home/ramblurr/.local/bin/ha-shutdown.py --timeout 60000 --port 5001 
Restart=always
RestartSec=10s
StandardError=journal
StandardOutput=journal
```

The env file is just a file holding the shared secret and looks like this:

```
HA_SHUTDOWN_TOKEN=a long secret
```

The HA script is below. It does a few things:

1. When triggered it sends a notification via the HA app to my phone. The notification has 2 actions "Abort" or "Continue"
2. I then have 2 minutes to Abort the shutdown if I want to.
3. If I continue or if the 2 minutes passes, it will then send an HTTP request to the listening python service.
4. It then turns off the smart plugs at my desk, turning of my monitor and other devices.

```yaml
alias: Quine Shutdown
sequence:
  - alias: Set up variables for the actions
    variables:
      action_abort_shutdown: "{{ 'ABORT_SHUTDOWN_' ~ context.id }}"
      action_continue_shutdown: "{{ 'CONTINUE_SHUTDOWN_' ~ context.id }}"
  - alias: Alert that Quine Shutdown is happening
    service: notify.mobile_app_samsungs21
    data:
      message: Quine is going to be shutdown. Abort?
      data:
        actions:
          - action: "{{ action_abort_shutdown }}"
            title: Abort
          - action: "{{ action_continue_shutdown }}"
            title: Continue
  - alias: Wait for a response
    timeout:
      minutes: "2"
    continue_on_timeout: true
    wait_for_trigger:
      - platform: event
        event_type: mobile_app_notification_action
        event_data:
          action: "{{ action_abort_shutdown }}"
      - platform: event
        event_type: mobile_app_notification_action
        event_data:
          action: "{{ action_continue_shutdown }}"
  - alias: Perform the action (or not)
    choose:
      - conditions: >-
          {{ (wait.trigger == None) or (wait.trigger.event.data.action ==
          action_continue_shutdown)  }}
        sequence:
          - service: rest_command.shutdown_quine
            data: {}
            # This turns of the smart plugs that my desk monitors and peripherals are plugged in to
          - service: switch.turn_off
            target:
              entity_id:
                - switch.shellyplug_plug_office_desk1_c
                - switch.shellyplug_plug_office_desk2_e
            data: {}
            enabled: false
      - conditions: "{{ wait.trigger.event.data.action == action_abort_shutdown }}"
        sequence:
          - service: notify.mobile_app_samsungs21
            data:
              message: Quine shutdown aborted.
mode: single

```

A sample automation to trigger this script looks like:

```
alias: "Office :: Quine :: Auto Shutdown"
description: ""
trigger:
  - platform: time
    at: "00:00:00"
condition:
  - condition: state
    entity_id: input_boolean.quine_shutdown_override
    state: "off"
action:
  - service: script.quine_shutdown
    data: {}
mode: single
```

Notice the input boolean override helper, this is a button on my dashboard I can
toggle to disable the shutdown in case my PC is doing something and shouldn't be
shutdown automatically.
    

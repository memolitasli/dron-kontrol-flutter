#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import math
from os import system, terminal_size
from queue import Empty
import struct
from sys import byteorder
import time
from tkinter.constants import CENTER, LEFT, W
from typing import Literal
from dronekit import VehicleMode, connect,LocationGlobalRelative,Vehicle,Command, mavlink
import argparse
from pymavlink import mavutil
import pyrebase
import tkinter as tk
import os
import datetime


gnd_speed = 5
modee      = 'GROUND'
parser = argparse.ArgumentParser(description='commands')
parser.add_argument('--connect')
parser.add_argument('--altitude')
args = parser.parse_args()
altitude= float(args.altitude)
connectionString = args.connect

drone = connect(connectionString,wait_ready=True)
print("Drona baglanildi...")


firebaseConfig = {

}

firebase = pyrebase.initialize_app(firebaseConfig)
auth = firebase.auth()
auth.sign_in_with_email_and_password("","")

db = firebase.database()

def firebaseGorevIndir():
    liste = []
    sayac = 0
    db = firebase.database()
    data = db.get()
    for nokta in data:
        wp = LocationGlobalRelative(float(nokta.val()['enlem']),float(nokta.val()['boylam']),float(nokta.val()['irtifa']))
        liste.append(wp)
        sayac = sayac +1
    print(str(sayac) + " Adet Nokta Eklendi, Baslangic Noktasi Ekleniyor...")
    wp_last = LocationGlobalRelative(drone.location.global_relative_frame.lat,drone.location.global_relative_frame.lon,drone.location.global_relative_frame.alt)
    liste.append(wp_last)
    return liste

def firebasenoktaGez():
    try:
        noktaListe = firebaseGorevIndir()
        for i in noktaListe:
            enlemFarki = i.lat - drone.location.global_relative_frame.lat
            boylamFarki = i.lon - drone.location.global_relative_frame.lon
            drone.simple_goto(i,groundspeed=gnd_speed,airspeed=5)
            while enlemFarki >= 0.0001 or boylamFarki >= 0.0001:
                enlemFarki = i.lat - drone.location.global_relative_frame.lat
                boylamFarki = i.lon - drone.location.global_relative_frame.lon
                time.sleep(1)
        print("Gorev Tamamlandi...")
    except:
        print("Bir sikinti var, lutfen baglantiyi ve gonderilen veriyi kontrol edin...")


def armAndTakeOff(tgt_altitute):
    print("Cihazda herhangi bir sikinti yok, Arm haline getiriliyor...")
    while not drone.is_armable:
        time.sleep(1)
    drone.mode = VehicleMode('GUIDED')
    drone.armed = True
    print("Kalkis Basliyor...")
    drone.simple_takeoff(tgt_altitute)

    while True:
        altit= drone.location.global_relative_frame.alt
        print("Yukseklik (metre) : " + str(altit))
        if altit >= tgt_altitute:
            print("Istenilen yukseklige ulasildi...")
            break
        time.sleep(1)



def printLambda():
    print('''
            - + - + @ @ @ - + - + - + -  + -
            - + - + - + -@ - + - + - + - + + 
            - + - + - + - @ - + - + - + -  +
            - + - + - + @  @ - + - + - + - +
            - + - + -  @ -  @ - - @ @  - + -
            - + - + - @      @ - @ - + - + -
            - - -@ @ @       @ @ - + - + - +
            - + - + - + Memoli - + - + - + -
            ''')

printLambda()

armAndTakeOff(altitude)

time.sleep(5)

firebasenoktaGez()

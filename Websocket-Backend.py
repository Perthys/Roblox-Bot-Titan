# Created by Sang#2180

import json, threading, time, os, requests, random, logging, websockets, asyncio, traceback
RobloxProcessName = "RobloxPlayerBeta.exe"
CLIENTS = set()

Configuration = {
    "PlaceID" : None,
    "TimeoutLength" : 35,
    "AmountOfBotsToRun" : 6,
    "MasterPlaceId" : None,
    "MasterJobId" : None,
}

UserIDsToCookies = {

}

Timeouts = {

}

OccupiedLimbs = [False, False, False, False, False, False]
CFrames = None

LimbsNames = [
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Torso",
    "Head"
]
def run(cmd):
    return os.popen(cmd).read().replace("\n", "")

def download(url,name):
    f = open(name, "wb")
    f.write(requests.get(url).content)
    f.close()
    return os.getcwd()+f"\\{name}"

def GetLatestClientPath():
    version_url = "https://s3.amazonaws.com/setup.roblox.com/version"
    version = requests.get(version_url).text.rstrip()
    
    paths = (
        os.environ["LOCALAPPDATA"] + "\\" + f"Roblox\\Versions\\{version}",
        os.environ["SYSTEMDRIVE"] + "\\" + f"Program Files (x86)\\Roblox\\Versions\\{version}",
        os.environ["SYSTEMDRIVE"] + "\\" + f"Program Files\\Roblox\\Versions\\{version}"
    )
    for path in paths:
        if os.path.isdir(path):
            return "'" + os.path.join(path, "RobloxPlayerBeta.exe") + "'"
        
    raise FileNotFoundError("Could not find path to Roblox client")

def ThreadFunction(target, Args = None):
    t = Args and threading.Thread(target=target, args=Args) or threading.Thread(target=target)
    t.daemon = True
    t.start()

def KillAllRobloxProcesses():
    return os.system("taskkill /IM RobloxPlayerBeta.exe")

def KillUserId(UserId):
    PID = Timeouts[UserId]["ProcessId"]
    if PID == 0:
        return
    return os.system(f"taskkill /F /PID {PID}")

def ReadFileLines(file):
    str = None
    with open(file, "r") as file:
        str = file.readlines()
        file.close()
    return str

def Get_XSRF_Token(token):
    xsrf = requests.post('https://auth.roblox.com/', cookies = {'.ROBLOSECURITY': token}).headers.get('x-csrf-token')
    return xsrf


def GetCookieData(Cookie):
    data = requests.get("https://users.roblox.com/v1/users/authenticated",
        cookies = {'.ROBLOSECURITY': Cookie},
        headers = {'x-csrf-token': Get_XSRF_Token(Cookie), "referer": "https://www.roblox.com"}
    ).json()
    return data

def EnsureGet(url):
    try:
        print("attempt to get cookie")
        return requests.get(url).text
    except Exception:
        print("failed, retrying")
        return EnsureGet(url)

with open("cookies.txt","r") as file:
    asd = json.loads(file.read())



def GetAccountCookie():
    Cookie = asd.pop()
    CookieData = GetCookieData(Cookie)
    UserId = CookieData.get("id")
    if not UserId:
        print("Failed to load cookie, using another")
        return GetAccountCookie()
    return Cookie, UserId

def UpdateRobloxProcessList(TargetBotId, processID):          
    Timeouts[TargetBotId]["ProcessId"] = processID
# Created by Sang#2180

def Join_Game_Function(Cookie):
    PlaceID = Configuration["MasterPlaceId"]
    JobID = Configuration["MasterJobId"]
    with requests.session() as session:
        session.cookies['.ROBLOSECURITY'] = Cookie
        session.headers['x-csrf-token'] = session.post('https://friends.roblox.com/v1/users/1/request-friendship').headers['x-csrf-token']
        auth_ticket = session.post('https://auth.roblox.com/v1/authentication-ticket/', headers={'referer':f'https://www.roblox.com/games/{PlaceID}'}).headers['rbx-authentication-ticket']
        BrowserId = random.randint(1000000, 10000000)
        print("Launching roblox instance..")
        JoinFlag = f"https://assetgame.roblox.com/game/PlaceLauncher.ashx?request=RequestGameJob&browserTrackerId={BrowserId}&placeId={PlaceID}&gameId={JobID}&isPlayTogetherGame=false"
        LaunchString = f'{GetLatestClientPath()} \'--app -t {auth_ticket} -j {JoinFlag} -b {BrowserId} --launchtime={time.time()*1000:0.0f} --rloc en_us --gloc en_us\' '
        Command = f"powershell \"(Start-Process  {LaunchString} -passthru).ID\" "
        return run(Command)
        
def OccupyLimbSlot():
    for i in range(len(OccupiedLimbs)):
        Limb = OccupiedLimbs[i]
        if Limb == False:
            OccupiedLimbs[i] = True
            print(LimbsNames[i])
            return i + 1 # lua index starts at 1

def LoadBot():
    Cookie, UserID = GetAccountCookie()
    UserIDsToCookies[UserID] = Cookie

    Timeouts[UserID] = {
        "LastPingTimestamp" : int(time.time()),
        "TimeoutStarted" : False,
        "FailedAttempts" : 0,
        "ProcessId" : 0,
        "LimbType" : OccupyLimbSlot()
    }
    JoinNewServer(UserID)

def DestroyAndReplaceBot(UserID):
    KillUserId(UserID)
    del UserIDsToCookies[UserID]
    del Timeouts[UserID]

    LoadBot()

async def Initialize(Arguments, websocket):
    global RobloxProcessCount, Configuration

    Configuration["MasterPlaceId"] = Arguments["MasterPlaceId"]
    Configuration["MasterJobId"] = Arguments["MasterJobId"]
    for _ in range(Configuration["AmountOfBotsToRun"]):
        LoadBot()
    ThreadFunction(ReduceLife)



async def Ping(Arguments, websocket):
    UserIDOfBot = Arguments["UserId"]
    Timeouts[UserIDOfBot]["LastPingTimestamp"] = int(time.time())

def JoinNewServer(UserIDOfBot):
    KillUserId(UserIDOfBot)
    BotData = Timeouts[UserIDOfBot]
    BotData["TimeoutStarted"] = True

    Cookie = UserIDsToCookies[UserIDOfBot]

    ProcessId = Join_Game_Function(Cookie)
    UpdateRobloxProcessList(UserIDOfBot, ProcessId)

def ReduceLife():
    while True:
        for UserIDOfBot in Timeouts.keys():
            BotStatus = Timeouts[UserIDOfBot]
            if not BotStatus["TimeoutStarted"]:
                continue 
            print(Configuration["TimeoutLength"] - (int(time.time()) - BotStatus["LastPingTimestamp"]))
            if int(time.time()) - BotStatus["LastPingTimestamp"] > Configuration["TimeoutLength"]:
                if BotStatus["FailedAttempts"] >= 2:
                    DestroyAndReplaceBot(UserIDOfBot)
                    continue
                JoinNewServer(UserIDOfBot)
                BotStatus["LastPingTimestamp"] = int(time.time())
                BotStatus["FailedAttempts"] += 1
        time.sleep(1)

async def GetSlots(Arguments, websocket):
    BotUserId = Arguments["UserId"]
    BotInformation = Timeouts[BotUserId]
    Response = json.dumps(["Slots", BotInformation["LimbType"]])
    await websocket.send(Response)
# Created by Sang#2180

async def BotBanned(Arguments, websocket):
    UserId = Arguments["UserId"]
    DestroyAndReplaceBot(UserId)

async def send(websocket, message):
    try:
        await websocket.send(message)
    except websockets.ConnectionClosed:
        pass

async def broadcast(message):
    global CLIENTS
    for websocket in CLIENTS:
        await send(websocket, message)

async def BroadcastCFrames(Arguments, websocket):
    LimbData = Arguments["LimbData"]
    CFrames = json.dumps(["MovementData", LimbData])
    await broadcast(CFrames)



Operations = {
    "Ping" : Ping,
    "GetSlots" : GetSlots,
    "BotBanned" : BotBanned,
    "BroadcastCFrames" : BroadcastCFrames, 
    "Initialize" : Initialize,
}



async def MessageCallback(Payload, websocket):
    Payload = json.loads(Payload)
    Operation = Payload.get("Operation")
    Arguments = Payload.get("Arguments")
    await Operations[Operation](Arguments, websocket)

# Created by Sang#2180

# python 😱😱😱

async def Handler(websocket):
    CLIENTS.add(websocket)
    while True: 
        try:
            Message = await websocket.recv()
            await MessageCallback(Message, websocket)
        except websockets.ConnectionClosed:
            CLIENTS.remove(websocket)
            break
        except Exception:
            print(traceback.format_exc())


async def main():
    async with websockets.serve(Handler, "localhost", 42069):
        await asyncio.Future()  # run forever

asyncio.run(main())
# Created by Sang#2180

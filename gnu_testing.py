import time
from julia import Main, Base, core
from pprint import pprint
from collections import namedtuple
import requests 
Main.include("board.jl")

HOST = 'localhost'  # <-- YOUR HOST HERE
PORT = 8001  # <-- YOUR PORT HERE

gnubgState = namedtuple('GNUState', ['agent', 'dice', 'board', 'double', 'winner', 'action', 'resigned'])

class GNUBG_Interface:
    def __init__(self, host, port):
        self.url = f"http://{host}:{port}"

    def send_command(self, command):
        try:
            resp = requests.post(url=self.url, data={"command": command})
            return self.parse_response(resp.json())
        except Exception as e:
            print(f"Error during connection to {self.url}: {e} (Remember to run gnubg -t -p bridge.py)"

    def parse_board(self, gnubg_board):
        black_pos = gnubg_board[0]
        white_pos = gnubg_board[1]
        board = Base.zeros(Base.Int8, Main.Boards.BOARD_POINTS)
        for i in range(len(white_pos)):
            if white_pos[i] > 0:
                if i == len(white_pos)-1:
                    board[26] = white_pos[i]
                else:
                    board[i+1] = white_pos[i]
        for i in range(len(black_pos)):
            if black_pos[i] > 0:
                if i == len(black_pos)-1:
                    board[27] = black_pos[i]
                else:
                    board[24-i] = -black_pos[i]
                    
        board[0] = 15 - sum(white_pos)
        board[25] = 15 - sum(black_pos)
        return board

    def parse_response(self, response):
        gnubg_board = response["board"]
        board = self.parse_board(gnubg_board)

        action = response["last_game"] if response["last_game"] else None
        
        info = response["info"] if response["info"] else None
        
        winner = None
        resigned = False
        double = False
        dice = ()
        agent = None

        if info:
            winner = info["winner"]
            resigned = info["resigned"] if "resigned" in info else None

        if action:
            agent = Main.Boards.WHITE_PLAYER if action["player"] == "O" else Main.Boards.BLACK_PLAYER
            if action["action"] == "double":
                double = True
            elif "dice" in action:
                dice = tuple(action["dice"])

        return gnubgState(agent=agent, dice=dice, board=board, double=double, winner=winner, action=action, resigned=resigned)
    
    def parse_julia_move(self, move):
        result = ""
        for step in move:
            start, end = step
            if start == Main.Boards.WHITE_BAR or start == Main.Boards.BLACK_BAR:
                result += f"bar/{end - 1},"
            elif end == Main.Boards.WHITE_OFF_THE_BOARD_POS or end == Main.Boards.BLACK_OFF_THE_BOARD_POS:
                result += f"{start - 1}/off,"
            else:
                result += f"{start - 1}/{end -1},"
        return result[:-1] #remove the last semicolon

class GNUBG_Env:
    DIFFICULTIES = ['beginner', 'intermediate', 'advanced', 'world_class']
    def __init__(self, gnubg_interface:GNUBG_Interface, difficulty='beginner'):
        self.gnubg = None
        self.gnubg_interface = gnubg_interface
        self.difficulty = difficulty
        self.is_difficulty_set = False

    def set_difficulty(self):
        self.is_difficulty_set = True

        self.gnubg_interface.send_command('set automatic roll off')
        self.gnubg_interface.send_command('set automatic game off')
        self.gnubg_interface.send_command('set display off')
        

        if self.difficulty == 'beginner':
            self.gnubg_interface.send_command('set player gnubg chequer evaluation plies 0')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation prune off')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation noise 0.060')
            self.gnubg_interface.send_command('set player gnubg cube evaluation plies 0')
            self.gnubg_interface.send_command('set player gnubg cube evaluation prune off')
            self.gnubg_interface.send_command('set player gnubg cube evaluation noise 0.060')

        elif self.difficulty == 'intermediate':
            self.gnubg_interface.send_command('set player gnubg chequer evaluation noise 0.040')
            self.gnubg_interface.send_command('set player gnubg cube evaluation noise 0.040')

        elif self.difficulty == 'advanced':
            self.gnubg_interface.send_command('set player gnubg chequer evaluation plies 0')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation prune off')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation noise 0.015')
            self.gnubg_interface.send_command('set player gnubg cube evaluation plies 0')
            self.gnubg_interface.send_command('set player gnubg cube evaluation prune off')
            self.gnubg_interface.send_command('set player gnubg cube evaluation noise 0.015')

        elif self.difficulty == 'world_class':
            self.gnubg_interface.send_command('set player gnubg chequer evaluation plies 2')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation prune on')
            self.gnubg_interface.send_command('set player gnubg chequer evaluation noise 0.000')
            
            self.gnubg_interface.send_command('set player gnubg movefilter 1 0 0 8 0.160')
            self.gnubg_interface.send_command('set player gnubg movefilter 2 0 0 8 0.160')
            self.gnubg_interface.send_command('set player gnubg movefilter 3 0 0 8 0.160')
            self.gnubg_interface.send_command('set player gnubg movefilter 3 2 0 2 0.040')
            self.gnubg_interface.send_command('set player gnubg movefilter 4 0 0 8 0.160')
            self.gnubg_interface.send_command('set player gnubg movefilter 4 2 0 2 0.040')

            self.gnubg_interface.send_command('set player gnubg cube evaluation plies 2')
            self.gnubg_interface.send_command('set player gnubg cube evaluation prune on')
            self.gnubg_interface.send_command('set player gnubg cube evaluation noise 0.000')

        self.gnubg_interface.send_command('save setting')

    def reset(self):
        self.gnubg = self.gnubg_interface.send_command("new session")
        if not self.is_difficulty_set:
            self.set_difficulty()
        
        dice = None if self.gnubg.agent == Main.Boards.BLACK_PLAYER else self.gnubg.dice
        return dice

    def roll_dice(self):
        self.gnubg = self.gnubg_interface.send_command("roll")
        self.handle_opponent_move()
    
    def step(self, action):
        game_over = False
        if action and self.gnubg.winner is None:
            action = self.gnubg_interface.parse_julia_move(action)
            self.gnubg = self.gnubg_interface.send_command(action)
        if self.gnubg.double and self.gnubg.winner is None:
            self.gnubg = self.gnubg_interface.send_command("take")
        
        if self.gnubg.agent == Main.Boards.WHITE_PLAYER and self.gnubg.action["action"] == "move" and self.gnubg.winner is None:
            if self.gnubg.winner != 'O':
                self.gnubg = self.gnubg_interface.send_command("accept")
                assert self.gnubg.winner == 'O', print(self.gnubg)
                assert self.gnubg.action['action'] == 'resign' and self.gnubg.agent == Main.Boards.BLACK_PLAYER and self.gnubg.action['player'] == 'X'
                assert self.gnubg.resigned
        
        winner = self.gnubg.winner
        if winner is not None:
            winner = Main.Boards.WHITE_PLAYER if winner == 'O' else Main.Boards.BLACK_PLAYER
            game_over = True
        
        return game_over
    

    def handle_opponent_move(self):
        previous_agent = self.gnubg.agent
        if previous_agent != Main.Boards.WHITE_PLAYER:
            while previous_agent != Main.Boards.WHITE_PLAYER and self.gnubg.winner is None:
                if self.gnubg.double:
                    self.gnubg = self.gnubg_interface.send_command("take")
                else:
                    self.gnubg = self.gnubg_interface.send_command("roll")
                previous_agent = self.gnubg.agent


def run_test_vs_gnubg(model_path, env:GNUBG_Env, episodes):
    model = Main.Models.load_model(model_path)
    wins = {Main.Boards.WHITE_PLAYER: 0, Main.Boards.BLACK_PLAYER: 0}
    for episode in range(episodes):
        first_roll = env.reset()
        t = time.time()
        game_over = False
        while not game_over:
            if first_roll:
                dice = first_roll
                first_roll = None
            else:
                env.roll_dice()
                dice = env.gnubg.dice
            next_action = Main.Models.select_action_gnubg(model, Main.Boards.WHITE_PLAYER, env.gnubg.board, dice)

            game_over = env.step(next_action)
            
        winner = Main.Boards.WHITE_PLAYER if env.gnubg.winner == 'O' else Main.Boards.BLACK_PLAYER
        wins[winner] += 1
        winner_name = "model" if winner == Main.Boards.WHITE_PLAYER else "GNUBG"
        #TODO: add the number of moves
        print(f"Episode {episode + 1}: Winner: {winner_name} in {time.time()-t} sec.")
    print(wins)
    


if __name__ == "__main__":
    interface = GNUBG_Interface(HOST, PORT)
    gnubg_env = GNUBG_Env(interface)
    model_path = "C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZeroRelu-20210801193120\\Main.Models.TDGammonZeroRelu-20210801193120-episode300000.bson"
    run_test_vs_gnubg(model_path, gnubg_env, 100)
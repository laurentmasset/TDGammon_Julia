import argparse
import os
import sys

TDGammonZero = "classic"
TDGammonZeroRelu = "classic_relu"
TDGammonZeroReluV2 = "relu_80"
TDGammonZeroLeakyRelu = "classic_leaky"
TDGammonZeroV2 = "classic_80"
TDGammonZeroV3 = "classic_20"
TDGammonZeroV4 = "classic_10"
TDGammonTDZero = "td0"
TDGammonMonteCarlo = "mc"
QGammonZero = "q0"
QGammonLambda = "ql"

MODEL_TYPE = [
    TDGammonZero,
    TDGammonZeroRelu,
    TDGammonZeroReluV2,
    TDGammonZeroLeakyRelu,
    TDGammonZeroV2,
    TDGammonZeroV3,
    TDGammonZeroV4,
    TDGammonTDZero,
    TDGammonMonteCarlo,
    QGammonZero,
    QGammonLambda
    ]

def get_model_info(model_path):
    model_dir, model_name = os.path.split(model_path)
    model_fullname, ext = os.path.splitext(model_name)
    model_basename = model_fullname[:model_fullname.rfind("-")]
    model_episode = int(model_fullname[model_fullname.rfind("-")+1:].replace("episode", ""))
    return model_dir, model_basename, model_episode

def train_with_args(args):
    episodes = args.eps
    alpha = args.alpha
    dr = args.dr
    save_path = args.save_path
    step = args.step
    resume = args.resume
    model_path = args.model_path

    if resume:
        print('Loading Julia code. Training should start soon...')

        if not model_path:
            print(f"The path to the model you want to resume from is missing or doesn't exist!")
            sys.exit()
        elif not os.path.exists(model_path):
            print(f"The path {model_path} doesn't exists!")
            sys.exit()
        
        if save_path is not None:
            print(f"You cannot use --save_path and --resume at the same time! The models to train will be placed in the resumed model directory.")
            sys.exit()
        
        model_dir, model_basename, model_episode = get_model_info(model_path)

        
        from julia import Main
        Main.include("board.jl")
        
        model = Main.Models.load_model(model_path)
        Main.Models.train(model, model_dir, step, alpha, dr, episodes, model_episode, model_basename)
    else:
        model_type = args.type
        if not save_path:
            print(f"The path is missing or doesn't exist!")
            sys.exit()
        elif not os.path.exists(save_path):
            print(f"The path {save_path} doesn't exists!")
            sys.exit()
        
        if model_path is not None:
            print(f"You cannot use --model_path if your are not resuming a model training!")

        print('Loading Julia code. Training should start soon...')
        
        from julia import Main
        Main.include("board.jl")

        if model_type == TDGammonZero:
            model = Main.Models.TDGammonZero()
        if model_type == TDGammonZeroRelu:
            model = Main.Models.TDGammonZeroRelu()
        if model_type == TDGammonZeroReluV2:
            model = Main.Models.TDGammonZeroReluV2()
        if model_type == TDGammonZeroLeakyRelu:
            model = Main.Models.TDGammonZeroLeakyRelu()
        if model_type == TDGammonZeroV2:
            model = Main.Models.TDGammonZeroV2()
        if model_type == TDGammonZeroV3:
            model = Main.Models.TDGammonZeroV3()
        if model_type == TDGammonZeroV4:
            model = Main.Models.TDGammonZeroV4()
        if model_type == TDGammonTDZero:
            model = Main.Models.TDGammonTDZero()
        if model_type == TDGammonMonteCarlo:
            model = Main.Models.TDGammonMonteCarlo()
        if model_type == QGammonZero:
            model = Main.Models.QGammonZero()
        if model_type == QGammonLambda:
            model = Main.Models.QGammonLambda()
        
        Main.Models.train(model, save_path, step, alpha, dr, episodes)

    
    

def test(args):
    last = args.last
    step = args.step
    episodes = args.eps
    resume = args.resume
    resume_from = args.resume_from
    count_backgammon = args.backgammon

    if not args.path:
        print(f"The path is missing or doesn't exist!")
        sys.exit()
    elif not os.path.exists(args.path):
        print(f"The path {args.path} doesn't exists!")
        sys.exit()
    else:
        path = args.path
    model_basename = str.split(path, "\\")[-2]

    print("Loading Julia code. Testing should start soon...")
    from julia import Main
    Main.include("board.jl")
    Main.Models.test_and_save_pubeval(path, model_basename, last, step, episodes, resume, resume_from, count_backgammon)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="TDGammon trainer", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    subparsers = parser.add_subparsers(help='Train Neural Network | Test Neural Network')
    
    train_parser = subparsers.add_parser('train', help='Train a neural network', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    train_parser.add_argument('--type', help='The type of neural network to train (not necessary to resume training)', type=str, choices=MODEL_TYPE, default=TDGammonZero)
    train_parser.add_argument('--eps', help='The number of episodes to train', type=int, default=1000000)
    train_parser.add_argument('--save_path', help='The directory path where to save new models (cannot be used with --resume or --model_path)', type=str, default=None)
    train_parser.add_argument('--alpha', help='The learning rate (alpha)', type=float, default=0.1)
    train_parser.add_argument('--dr', help='The decay rate (lambda) (ignored if not necessary)', type=float, default=0.7)
    train_parser.add_argument('--step', help='The frequency of saving the model in number of episodes', type=int, default=1000)
    train_parser.add_argument("--resume", help="Specify that you want to resume a stopped training (cannot be used with --path)", action='store_true')
    train_parser.add_argument('--model_path', help='The model path where to find the model to resume training from (used with --resume, cannot be used with --path)', type=str, default=None)
    

    train_parser.set_defaults(func=train_with_args)

    test_parser = subparsers.add_parser('test', help='Test neural netwok(s)', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    test_parser.add_argument("--path", help="The directory path where to find the models to test", type=str, default=None)
    test_parser.add_argument("--last", help="The last model number", type=int, required=True)
    test_parser.add_argument("--step", help="The frequency of model episodes to test (ex. test every 10000 episodes)", type=int, default=10000)
    test_parser.add_argument("--eps", help="The number of episodes to test for each step episode (will be played twice, one time for each color)", type=int, default=5000)
    test_parser.add_argument("--resume", help="Specify that you want to resume a stopped test", action='store_true')
    test_parser.add_argument("--resume_from", help="Specify the first episode to resume from (used with --resume)", type=int, default=0)
    test_parser.add_argument("--backgammon", help="Specify that you want to count the backgammon points", action='store_true')

    test_parser.set_defaults(func=test)
      
    

    args = parser.parse_args()
    args.func(args)
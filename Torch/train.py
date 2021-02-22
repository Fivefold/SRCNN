import torch
from torch import nn
import torch.optim as optim
import torch.backends.cudnn as cudnn
from torch.utils.data.dataloader import DataLoader

import os
import copy
import argparse

from tqdm import tqdm
from models import SRCNN
from datasets import Train_Dataset, Eval_Dataset
from util import Average, psnr

# Train the neural network with images to gain new weights & biases
# e.g. for a different scale.
# You need two .h5 files: one for training and one for evaluating
# the upscaling of the network in training.
# .h5 files can be generated with ./prepare.py
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # .h5 file to train the network with
    parser.add_argument('--train-file', type=str, required=True)
    # Different .h5 file (e.g. from Set5) to evaluate upscaling performance with
    parser.add_argument('--eval-file', type=str, required=True)
    # Directory to output the weight files from each epoch to
    parser.add_argument('--outputs-dir', type=str, required=True)
    # Upscaling factor
    parser.add_argument('--scale', type=int, default=3)
    parser.add_argument('--lr', type=float, default=1e-4)
    parser.add_argument('--seed', type=int, default=1)
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--num-epochs', type=int, default=100)
    parser.add_argument('--num-workers', type=int, default=8)

    args = parser.parse_args()

    args.outputs_dir = os.path.join(args.outputs_dir, 'x{}'.format(args.scale))

    if not os.path.exists(args.outputs_dir):
        os.makedirs(args.outputs_dir)

    cudnn.benchmark = True
    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

    torch.manual_seed(args.seed)

    model = SRCNN().to(device)
    criterion = nn.MSELoss()
    optimizer = optim.Adam([
        {'params': model.conv1.parameters()},
        {'params': model.conv2.parameters()},
        {'params': model.conv3.parameters(), 'lr': args.lr * 0.1}
    ], lr=args.lr)

    train_dataset = Train_Dataset(args.train_file)
    train_dataloader = DataLoader(dataset=train_dataset,
                                  batch_size=args.batch_size,
                                  shuffle=True,
                                  num_workers=args.num_workers,
                                  pin_memory=True,
                                  drop_last=True)
    eval_dataset = Eval_Dataset(args.eval_file)
    eval_dataloader = DataLoader(dataset=eval_dataset, batch_size=1)

    best_weights = copy.deepcopy(model.state_dict())
    best_epoch = 0
    best_psnr = 0

    for epoch in range(args.num_epochs):
        model.train()
        epoch_losses = Average()

        with tqdm(total=(len(train_dataset) - len(train_dataset) % args.batch_size)) as prog:
            prog.set_description(
                'epoch: {}/{}'.format(epoch, args.num_epochs - 1))

            for data in train_dataloader:
                inputs, labels = data

                inputs = inputs.to(device)
                labels = labels.to(device)

                conv = model(inputs)

                loss = criterion(conv, labels)

                epoch_losses.update(loss.item(), len(inputs))

                optimizer.zero_grad()
                loss.backward()
                optimizer.step()

                prog.set_postfix(loss='{:.6f}'.format(epoch_losses.avg))
                prog.update(len(inputs))

        torch.save(model.state_dict(), os.path.join(
            args.outputs_dir, 'epoch_{}.pth'.format(epoch)))

        model.eval()
        epoch_psnr = Average()

        for data in eval_dataloader:
            inputs, labels = data

            inputs = inputs.to(device)
            labels = labels.to(device)

            with torch.no_grad():
                conv = model(inputs).clamp(0.0, 1.0)

            epoch_psnr.update(psnr(conv, labels), len(inputs))

        print('eval psnr: {:.2f}'.format(epoch_psnr.avg))

        if epoch_psnr.avg > best_psnr:
            best_epoch = epoch
            best_psnr = epoch_psnr.avg
            best_weights = copy.deepcopy(model.state_dict())

    print('best epoch: {}, psnr: {:.2f}'.format(best_epoch, best_psnr))
    torch.save(best_weights, os.path.join(args.outputs_dir, 'best.pth'))

mkdir -p ~/miniconda3
# wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
cp /workspace/assets/Miniconda3-latest-Linux-x86_64.sh ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash
# source ~/miniconda3/bin/activate
# conda init --all
conda create -n python3.13 python=3.13
# 腾讯云镜像源s
# pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple

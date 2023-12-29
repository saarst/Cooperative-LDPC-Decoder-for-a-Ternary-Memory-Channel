<h2 align="center">Cooperative LDPC Decoder for a Ternary Memory Channel</h2> 
<h2 align="center">Project in Technion's EE faculty (044167)</h2> 
<h4 align="center">Design  and simulate of a new decoder for LDPC-Barrier code</h4> 


  <p align="center">
    Saar Stern: <a href="https://www.linkedin.com/in/saar-stern-a43413246/">LinkedIn</a> , <a href="https://github.com/saarst">GitHub</a>
  <br>
    Yoav Cohen: <a href="https://www.linkedin.com/in/cohen-yoav/">LinkedIn</a> , <a href="https://github.com/yoavcohe">GitHub</a>
  <br>
  Supervised by:
 <br>
    Yuval Ben-Hur: <a href="https://www.linkedin.com/in/yuval-ben-hur-16880912a/">LinkedIn</a> , <a href="https://github.com/benhuryuval">GitHub</a>
 </p>

- [Cooperative LDPC Decoder for a Ternary Memory Channel](#Cooperative-LDPC-Decoder-for-a-Ternary-Memory-Channel)
  * [Background](#background)
  * [Results](#results)
  * [Files in the repository](#files-in-the-repository)
  * [API](#api-mplpy---help)
  * [Usage](#usage)
  * [References](#references)

## Background
In this project, we developed a new decoding algorithm for error correction over a ternary “Barrier” channel. This channel has three symbols at its input and output, where one of the symbols is defined as a "barrier" symbol. When the "barrier" symbol is transmitted, the channel's output can be any of the three symbols, but when a non-barrier symbol is transmitted, the channel's output can only be the transmitted symbol or the "barrier" symbol.

The ternary barrier channel:

![The ternay barrier channel](https://github.com/saarst/TriLDPC/blob/main/Figures/readme/Ternary_Barrier_Channel.png)

A prior construction of error correcting codes for the ternary barrier channel uses a special mapping of two binary codes onto the ternary alphabet. In this project, we developed and implemented such a construction using LDPC (Low-Density Parity-Check) codes. The primary contribution of this project is the proposal of a new and efficient iterative decoder for the proposed code, which allows for improved error rates and/or reduced computational complexity compared to previous decoders.

## Results
Simulation of the prior decoder and the joint (ours) decoder with Matlab (needs parallel computing toolbox), executed on Technion's HPC.

![alt](https://github.com/saarst/TriLDPC/blob/main/Figures/svg256_sep/TriLDPC_n256_Ri075_Rr05.svg)

## Files in the repository

| File name                                                     | Purpsoe                                                                                                                                       |
|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `ternary_batch_simulation_main.m`                         | main simulation                                                                                                              |
| `ternary_enc_LDPCLDPC.m`                                               | ternary LDPC-Barrier encoder                                                                                                  |
| `asymmchannel.m`                                               | Barrier channel                                                                                          |
| `gfrref.m`                                                 | auxiliary function of the encoder                                                                         |
| `RunPBS.m`                                                 | PBS wrapper                                           |
| `PBS_main.sh`                                                | PBS script                                     |
| `gen_par_mats`                                                    | library for generating PCMs   |
| `LDPCcode`                                                    | folder for the PCMs that were generated   |
| `LDPC`                                                    | decoders(for BSC, prior, ours) , channel LLRs, and aux functions|
| `Tests`                                        | skelton of tests
| `logs`                                        | empty folder for logs
| `Plot`                                        | plot functions
| `Results`                                        | all results
| `Figures`                                        | all figures

## API
You should use the `ternary_batch_simulation_main.m` file with the following arguments:


|Argument                 | Description                                 |
|-------------------------|---------------------------------------------|
|  --n |           block length
|  --log_p |   log of p (down error probability)
|  --log_q |   log of q (up error probability)
|  --rate_ind  | rate of indicator code
|  --rate_res  | rate of residual code
|  --num_iter_sim | number of iterations in the simulation
|  --sequenceInd | hyper-parameter of the decoder
|  --sequenceRes | hyper-parameter of the decoder
|  --ResultsFolder | folder to save the results in|

## Usage

Clone the repository and run:
```
ternary_batch_simulation_main()
```
if you run on PBS like we did, run:
```
Tests/Tests.m
```

## References

* Y.Ben-Hur,Y.Cassuto [“Coding on Dual-Parameter Barrier Channels beyond Worst-Case Correction“](https://ieeexplore.ieee.org/document/9685188), 2021
* Y.Mazal [LDPC website](https://yairmz.github.io/LDPC/ldpc_overview/log_spa.html) and [github](https://github.com/YairMZ/belief_propagation)







<h2 align="center">Cooperative LDPC Decoder for a Ternary Memory Channel</h2> 
<h2 align="center">Project A in Technion's EE faculty (044167)</h2> 
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
  * [API (`MPL.py --help`)](#api-mplpy---help)
  * [Usage](#usage)
  * [References](#references)


In this project, we developed a new decoding algorithm for error correction over a ternary “Barrier” channel. This channel has three symbols at its input and output, where one of the symbols is defined as a "barrier" symbol. When the "barrier" symbol is transmitted, the channel's output can be any of the three symbols, but when a non-barrier symbol is transmitted, the channel's output can only be the transmitted symbol or the "barrier" symbol.


A prior construction of error correcting codes for the ternary barrier channel uses a special mapping of two binary codes onto the ternary alphabet. In this project, we developed and implemented such a construction using LDPC (Low-Density Parity-Check) codes. The primary contribution of this project is the proposal of a new and efficient iterative decoder for the proposed code, which allows for improved error rates and/or reduced computational complexity compared to previous decoders.

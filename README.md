
# Image Encryption Algorithm Based on BAMNN and Piecewise Chaotic Mapping

This repository provides the official implementation and simulation codes for the image encryption and decryption algorithm proposed in our paper submitted to *Chaos, Solitons & Fractals*.

---

## 📌 Prerequisites & Environment

- **Platform**: MATLAB (Tested on R2024a)
- **Toolboxes**: Image Processing Toolbox (for basic image I/O and display)

---

## 📂 Repository Structure

- `U1.mat,U2.mat,V1.mat,V2.mat` — Numerical simulation of BAMNN state trajectories and generation of chaotic sequences.
- `paper9.m` — Main routine executing the entire pipeline (Steps I–IV: matrix expansion, quantization, double-XOR encryption, and inverse decryption).
- `cameraman.jpg` — Standard $256 \times 256$ grayscale benchmark image.
- `calculate_NPCR.m, calculate_UACI.m, calculate_correlations_fast.m` — Evaluation metrics (Histogram, Adjacent Pixel Correlation, Information Entropy, NPCR, and UACI).

*(Note: Adjust the file names above according to your actual uploaded script names.)*

---

## 🚀 How to Run

1. **Clone or Download** this repository to your local directory.
2. Open MATLAB and set the current working folder to the repository path.
3. Run the complete encryption and decryption workflow:
   ```matlab
   run('paper9.m')

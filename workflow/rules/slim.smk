def get_h(wildcards):
        h = parameters.loc[parameters["ID"] == wildcards.ID, "h"]
        return float(h.iloc[0])

def get_sweepS(wildcards):
        sweepS = parameters.loc[parameters["ID"] == wildcards.ID, "sweepS"]
        return float(sweepS.iloc[0])

def get_sigma(wildcards):
        sigma = parameters.loc[parameters["ID"] == wildcards.ID, "sigma"]
        return float(sigma.iloc[0])

def get_N(wildcards):
        N = parameters.loc[parameters["ID"] == wildcards.ID, "N"]
        return float(N.iloc[0])

def get_mu(wildcards):
        mu = parameters.loc[parameters["ID"] == wildcards.ID, "mu"]
        return float(mu.iloc[0])

def get_R(wildcards):
        R = parameters.loc[parameters["ID"] == wildcards.ID, "R"]
        return float(R.iloc[0])

def get_tau(wildcards):
        tau = parameters.loc[parameters["ID"] == wildcards.ID, "tau"]
        return float(tau.iloc[0])

def get_f0(wildcards):
        f0 = parameters.loc[parameters["ID"] == wildcards.ID, "f0"]
        return float(f0.iloc[0])

def get_f1(wildcards):
        f1 = parameters.loc[parameters["ID"] == wildcards.ID, "f1"]
        return float(f1.iloc[0])

def get_n(wildcards):
        n = parameters.loc[parameters["ID"] == wildcards.ID, "n"]
        return float(n.iloc[0])

def get_lambda(wildcards):
        lamb = parameters.loc[parameters["ID"] == wildcards.ID, "lambda"]
        return float(lamb.iloc[0])

def get_r(wildcards):
        r = parameters.loc[parameters["ID"] == wildcards.ID, "r"]
        return float(r.iloc[0])

def get_K(wildcards):
        K = parameters.loc[parameters["ID"] == wildcards.ID, "K"]
        return float(K.iloc[0])

def get_M(wildcards):
        M = parameters.loc[parameters["ID"] == wildcards.ID, "M"]
        return float(M.iloc[0])

def get_U(wildcards):
        U = parameters.loc[parameters["ID"] == wildcards.ID, "U"]
        return float(U.iloc[0])

def get_B(wildcards):
        B = parameters.loc[parameters["ID"] == wildcards.ID, "B"]
        return float(B.iloc[0])

def get_hU(wildcards):
        hU = parameters.loc[parameters["ID"] == wildcards.ID, "hU"]
        return float(hU.iloc[0])

def get_hB(wildcards):
        hB = parameters.loc[parameters["ID"] == wildcards.ID, "hB"]
        return float(hB.iloc[0])

def get_bBar(wildcards):
        bBar = parameters.loc[parameters["ID"] == wildcards.ID, "bBar"]
        return float(bBar.iloc[0])

def get_uBar(wildcards):
        uBar = parameters.loc[parameters["ID"] == wildcards.ID, "uBar"]
        return float(uBar.iloc[0])

def get_alpha(wildcards):
        alpha = parameters.loc[parameters["ID"] == wildcards.ID, "alpha"]
        return float(alpha.iloc[0])

def get_ncf(wildcards):
        ncf = parameters.loc[parameters["ID"] == wildcards.ID, "ncf"]
        return float(ncf.iloc[0])

def get_cl(wildcards):
        cl = parameters.loc[parameters["ID"] == wildcards.ID, "cl"]
        return float(cl.iloc[0])

def get_fsimple(wildcards):
        fsimple = parameters.loc[parameters["ID"] == wildcards.ID, "fsimple"]
        return float(fsimple.iloc[0])

rule slim:
	input:
		"../config/parameters.tsv"
	output:
		finalTable=temp("data/tables/slim_{ID}.table"),
		tmpVCF = temp("slim_{ID}.vcf"),
		fixTime = "data/fix_times/fix_time_{ID}.txt"
	log:
		"logs/slim/{ID}.log"
	params:
		sweepS=get_sweepS,
		sigma=get_sigma,
		h=get_h,
		N=get_N,
		mu=get_mu,
		R=get_R,
		tau=get_tau,
		f0=get_f0,
		f1=get_f1,
		n=get_n,
		lamb=get_lambda,
		r=get_r,
		K=get_K,
		M=get_M,
		U=get_U,
		B=get_B,
		hU=get_hU,
		hB=get_hB,
		bBar=get_bBar,
		uBar=get_uBar,
		alpha=get_alpha,
		ncf=get_ncf,
		cl=get_cl,
		fsimple=get_fsimple
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/slim.yml"
	shell:
		"""
		# run simulation
		slim -d ID={wildcards.ID} -d sweepS={params.sweepS} -d sigma={params.sigma} -d h={params.h} -d N={params.N} -d mu={params.mu} -d R={params.R} -d tau={params.tau} -d f0={params.f0} -d f1={params.f1} -d n={params.n} -d lambda={params.lamb} -d r={params.r} -d K={params.K} -d M={params.M} -d U={params.U} -d B={params.B} -d hU={params.hU} -d hB={params.hB} -d bBar={params.bBar} -d uBar={params.uBar} -d alpha={params.alpha} -d ncf={params.ncf} -d cl={params.cl} -d fsimple={params.fsimple} scripts/simulation.slim &> {log}

		# move fix time to it's own directory
		mkdir -p data/fix_times
		mv fix_time_{wildcards.ID}.txt data/fix_times/

		# move fails to it's own directory
		mkdir -p data/fails
		mv fails_{wildcards.ID}.txt data/fails/

		# convert vcf to simple table
		# remove hastag from CHROM
		# remove multiallelic sites, because most studies focus on just bialleleic SNPs
		# convert genotypes to 0s and 1s
		grep -v ^## {output.tmpVCF} | grep -v "MULTIALLELIC" | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > {output.finalTable}
		"""

## get full vcf
wget http://1001genomes.org/data/GMI-MPI/releases/v3.1/1001genomes_snp-short-indel_only_ACGTN.vcf.gz

## get accessions
wget -O accessions.csv https://tools.1001genomes.org/api/accessions.csv?query=SELECT%20*%20FROM%20tg_accessions%20ORDER%20BY%20id

## create populations file for pixy, need to remove extra commas within csv to properly subset
sed 's/Bozen, Guntschnaberg/Bozen/g' accessions.csv | sed 's/MPI,Salk/MPISalk/g' | sed 's/Salk,GMI/SalkGMI/g' | sed 's/GMI,Salk/GMISalk/g' | sed 's/Salk,MPI/SalkMPI/g' | sed 's/MPI,GMI/MPIGMI/g' | sed 's/Monsanto,MPI/MonsantoMPI/g' | sed 's/Outgate, east side/Outgate/g' | sed 's/Dove Cottage,Wordsworth Trust, nr Grasmere/Dove Cottage/g' | cut -f1,11 --delimiter=","  | sed 's|,|\t|g' | sed 's|"||g' > populations.tsv

## split vcf by chromosome
bcftools index 1001genomes_snp-short-indel_only_ACGTN.vcf.gz
bcftools index -s 1001genomes_snp-short-indel_only_ACGTN.vcf.gz | cut -f 1 | while read C; do bcftools view -O z -o ${C}.vcf.gz 1001genomes_snp-short-indel_only_ACGTN.vcf.gz  "${C}" ; done

## tabix index split vcfs, for pixy
tabix 1.vcf.gz
tabix 2.vcf.gz
tabix 3.vcf.gz
tabix 4.vcf.gz
tabix 5.vcf.gz

## calculate fst with pixy
pixy --stats fst --vcf 1.vcf.gz --populations populations.tsv --window_size 10000 --bypass_invariant_check yes --output_prefix chr1 --n_cores 4 --chunk_size 10000

## create sample files for each subpopulation
grep "admixed" populations.tsv | cut -f1 > admixed.txt
grep "asia" populations.tsv | cut -f1 > asia.txt
grep "cetral_europe" populations.tsv | cut -f1 > central_europe.txt
grep "germany" populations.tsv | cut -f1 > germany.txt
grep "italy_balkan_caucasus" populations.tsv | cut -f1 > italy_balkan_caucasus.txt
grep "north_sweden" populations.tsv | cut -f1 > north_sweden.txt
grep "relict" populations.tsv | cut -f1 > relict.txt
grep "south_sweden" populations.tsv | cut -f1 > south_sweden.txt
grep "spain" populations.tsv | cut -f1 > spain.txt
grep "western_europe" populations.tsv | cut -f1 > western_europe.txt

mkdir popfiles
mv admixed.txt popfiles/
mv asia.txt popfiles/
mv central_europe.txt popfiles/
mv germany.txt popfiles/
mv italy_balkan_caucasus.txt popfiles/
mv north_sweden.txt popfiles/
mv relict.txt popfiles/
mv south_sweden.txt popfiles/
mv spain.txt popfiles/
mv western_europe.txt popfiles/

## split vcfs by subpopulation
## exclude non-snps
## exclude >bi-allelic sites
## exclude sites with >10% missing genotype calls
## convert remaining missing genotype calls to homozygous reference
## remove all format columns besides GT
## format VCF file for input to R script that generate images
for chrom in {1..5}
do
	for popfile in popfiles/*.txt
	do
		echo Splitting chromosome $chrom by $popfile...
		bcftools view -m2 -M2 -v snps --samples-file $popfile -i 'F_MISSING<0.1' $(echo $chrom).vcf.gz | bcftools +missing2ref - -- -p | bcftools annotate -x "FORMAT" | grep -v ^## | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > $chrom_$(basename $popfile).vcf
	done
done
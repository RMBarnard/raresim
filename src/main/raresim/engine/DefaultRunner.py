from src.main.raresim.common.sparse import *
from src.main.raresim.common.legend import *
from src.main.raresim.engine import RunConfig
from src.main.raresim.engine.transformers import *
from src.main.raresim.common.exceptions import *
from src.main.raresim.common import BinsReader


class DefaultRunner:
    def __init__(self, runConfig: RunConfig):
        self.matrix_reader = SparseMatrixReader()
        self.matrix_writer = SparseMatrixWriter()
        self.bins_reader = BinsReader()
        self.legend_reader_writer = LegendReaderWriter()
        self.args = runConfig.args
        self.runConfig = runConfig

    def run(self):
        # Start with loading all the necessary data
        matrix: SparseMatrix = self.matrix_reader.loadSparseMatrix(self.args.sparse_matrix)
        legend: Legend = self.legend_reader_writer.load_legend(self.args.input_legend)
        bins = self.get_bins()

        # Validate inputs
        if legend.row_count() != matrix.num_rows():
            raise IllegalArgumentException(f"Legend and Hap file lengths do not match. \n"
                                           f"Legend: {legend.row_count()}, Haps: {matrix.num_rows()}")

        if self.args.input_legend is None or self.args.output_legend is None:
            raise IllegalArgumentException("Legend files not provided")

        transformer = self.get_transformer()
        transformer.run(bins, legend, matrix)

        print()
        print('Writing new variant legend')
        self.legend_reader_writer.write_legend(legend, self.args.output_legend)

        print()
        print('Writing new haplotype file', end='', flush=True)
        self.matrix_writer.writeToHapsFile(matrix, self.args.output_hap)

    def get_bins(self):
        mode = self.runConfig.run_type
        bins = None
        if mode =="func_split":
            bins = {}
            bins['fun'] = self.bins_reader.loadBins(self.args.exp_fun_bins)
            bins['syn'] = self.bins_reader.loadBins(self.args.exp_syn_bins)
        elif mode == "syn_only":
            bins = self.bins_reader.loadBins(self.args.syn_bins_only)
        elif mode == "fun_only":
            bins = self.bins_reader.loadBins(self.args.fun_bins_only)
        else:
            bins = self.bins_reader.loadBins(self.args.exp_bins)
        return bins

    def get_transformer(self):
        mode = self.runConfig.run_type
        print(f"Running with run mode: {mode}")
        if mode == "standard":
            return StandardTransformer(self.runConfig)
        if mode == "func_split":
            return FunctionalSplitTransformer(self.runConfig, ["fun", "syn"])
        if mode == "fun_only":
            return FunctionalSplitTransformer(self.runConfig, ["fun"])
        if mode == "syn_only":
            return FunctionalSplitTransformer(self.runConfig, ["syn"])
        if mode == "probabilistic":
            return ProbabilisticTransformer(self.runConfig)

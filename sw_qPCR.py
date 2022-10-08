import glob, os, string
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def layout_to_annotation(plate_id,
                         data_folder='../data/qPCR-data',
                         template_layout_file=None,
                         primer_layout_file=None):
    '''
    '''
    if template_layout_file is None:
        template_layout_files = glob.glob(os.path.join(data_folder, '*'+plate_id+'*template*layout*.csv'))
        assert len(template_layout_files) == 1
        template_layout_file = template_layout_files[0]
    
    if primer_layout_file is None:
        primer_layout_files = glob.glob(os.path.join(data_folder, '*'+plate_id+'*primer*layout*.csv'))
        assert len(primer_layout_files) == 1
        primer_layout_file = primer_layout_files[0]
    
    # Extract template information
    with open(template_layout_file, 'r') as f:
        lines = f.readlines()
    assert lines[0].startswith('template')
    
    template_list = []
    for line in lines[1:]:
        temp = line.strip().split(',')
        assert len(temp) == 13
        template_list = template_list + temp[1:]

    assert len(template_list) == 96
    
    # Extract primer information
    with open(primer_layout_file, 'r') as f:
        lines = f.readlines()
    assert lines[0].startswith('primer')
    
    primer_list = []
    for line in lines[1:]:
        temp = line.strip().split(',')
        assert len(temp) == 13
        primer_list = primer_list + temp[1:]

    assert len(primer_list) == 96
    
    wells = []
    for i in string.ascii_uppercase[:8]:
        for j in range(1,13):
            wells.append(i+'{:02d}'.format(j))
    
    annotation_file = os.path.join(data_folder, plate_id+'-annotation.csv')
    with open(annotation_file, 'w') as f:
        f.write(','.join(['Well', 'Sample', 'Primer']) + '\n')
        for i in range(96):
            f.write(','.join([wells[i], template_list[i], primer_list[i]]) + '\n')
            
def get_plate_data(plate_id, data_folder='../data/qPCR-data', sgRNA_test=True):
    ''' Given a plate id:
          1. Locate the annotation csv file and the quantification Cq results csv file
          2. Extract useful data, merge and return the data frame
    '''
    
    annotation_files = glob.glob(os.path.join(data_folder, '*'+plate_id+'*annotation.csv'))
    if len(annotation_files) == 0:
        layout_to_annotation(plate_id)
    assert len(annotation_files) == 1
    annotation_file = annotation_files[0]
    
    exported_csv_folders = glob.glob(os.path.join(data_folder, '*'+plate_id+'*'+os.path.sep))
    assert len(exported_csv_folders) == 1
    exported_csv_folder = exported_csv_folders[0]
    
    data_files = glob.glob(os.path.join(exported_csv_folder, '*Quantification Cq Results.csv'))
    assert len(data_files) == 1
    data_file = data_files[0]
    
    df = pd.read_csv(annotation_file)
    df_annotation = df[['Well', 'Sample', 'Primer']]
    
    df = pd.read_csv(data_file)
    df_data = df[['Well', 'Cq']]
    
    df = df_annotation.merge(df_data, on='Well')
    df.dropna(inplace=True)
    
    df['plate_id'] = [plate_id]*len(df)
    
    if sgRNA_test:
        # [f(x) if condition else g(x) for x in sequence]
        df['sgRNA_id'] = [i.split('-')[1] if len(i.split('-'))>1 else i for i in df.Sample.tolist()]
    
    return df

def get_expression_data(df, test_primer, ref_primer='Rps29 v1', sgRNA_test=True):
    ''' From the data frame containing qPCR data and annotation, 
        calculate average values of replicates and deltaCq values of each sample
        
    '''
    for i in ['Well', 'Sample', 'Primer', 'Cq']:
        assert i in df.columns
    
    df_ref = df[df.Primer==ref_primer]
    df_ref.rename(columns={'Cq': 'Cq_ref'}, inplace=True)
    
    df_test = df[df.Primer==test_primer]
    df_test.rename(columns={'Cq': 'Cq_test'}, inplace=True)
    
    # calculate average values of technical replicates
    df_ref_mean = df_ref.groupby('Sample').mean()
    df_ref_mean.reset_index(inplace=True)
    
    df_test_mean = df_test.groupby('Sample').mean()
    df_test_mean.reset_index(inplace=True)
    
    df = df_ref_mean.merge(df_test_mean, on='Sample')
    df['deltaCq'] = df.Cq_test - df.Cq_ref
    df['relExp'] = 2**(-df.deltaCq)
    df['Group'] = [df.Sample[i][:-2] for i in range(len(df))]
    if sgRNA_test:
        df['sgRNA_id'] = [i.split('-')[1] if len(i.split('-'))>1 else i for i in df.Sample.tolist()]
    
    return df

def get_annotation_data(plate_id, data_folder='../data/qPCR-data'):
    '''Get annotation data from the plate_id'''
    
    annotation_files = glob.glob(os.path.join(data_folder, '*'+plate_id+'*annotation.csv'))
    if len(annotation_files) == 0:
        layout_to_annotation(plate_id)
    assert len(annotation_files) == 1
    annotation_file = annotation_files[0]

    df = pd.read_csv(annotation_file)
    df_annotation = df[['Well', 'Sample', 'Primer']]
    df_annotation.dropna(inplace=True)
    
    return df_annotation
                        
def get_melting_curves_data(plate_id, data_folder='../data/qPCR-data'):
    ''' Given a plate id:
          1. Locate the annotation csv file and the melting curves csv file
          2. Extract useful data, merge and return the data frame
    '''
    
    exported_csv_folders = glob.glob(os.path.join(data_folder, '*'+plate_id+'*'+os.path.sep))
    assert len(exported_csv_folders) == 1
    exported_csv_folder = exported_csv_folders[0]
    
    data_files = glob.glob(os.path.join(exported_csv_folder, '*Melt Curve Derivative Results_SYBR.csv'))
    assert len(data_files) == 1
    data_file = data_files[0]
    
    df = pd.read_csv(data_file)
    
    # drop the first column (empty)
    df = df.iloc[:, 1:]
    
    # wells = []
    # for i in string.ascii_uppercase[:8]:
    #     for j in range(1,13):
    #         wells.append(i+'{:02d}'.format(j))
    
    # rename columns to keep the well names consistent
    # df.columns = ['Temperature'] + wells
    col_names = df.columns.tolist()
    df.columns = [i[0]+'0'+i[1] if len(i)==2 else i for i in col_names]
    
    return df

def plot_melting_curves(plate_id,
                        primer=None,
                        fig_width=2.8,
                        fig_height=1.2,
                        line_width=0.8,
                        exclude_wells=None,
                        sample=None,
                        save_fig=True,
                        output_folder = '../jupyter_figures',
                        data_folder='../data/qPCR-data'):
    '''Plot melting curves of the specificied plate_id and primer'''

    df_annotation = get_annotation_data(plate_id, data_folder)
    
    # select the wells based on the query of primer and sample
    if primer is None:
        df_selected = df_annotation
        primers = df_annotation.Primer.unique()
        # primers_simple = [i.split(' ')[0] for i in primers]
        primers_simple = [i.replace(' ', '') for i in primers]
        primer_simple = '_'.join(primers_simple)
    elif type(primer) is str:
        df_selected = df_annotation[df_annotation.Primer==primer]
        primer_simple = primer.replace(' ', '')
    elif type(primer) is list:
        df_selected = df_annotation[df_annotation.Primer.isin(primer)]
        primers_simple = [i.replace(' ', '') for i in primer]
        primer_simple = '_'.join(primers_simple)
        
    if sample is not None:
        if type(sample) is str:
            df_selected = df_selected[df_selected.Sample==sample]
        elif type(sample) is list:
            df_selected = df_selected[df_selected.Sample.isin(sample)]
    
    if len(df_selected) == 0:
        return
    
    fig = plt.figure(figsize=(fig_width,fig_height), dpi=300)
    ax = fig.add_axes([0.1, 0.1, 0.8, 0.8])
    
    df = get_melting_curves_data(plate_id, data_folder)
    for well in df_selected.Well.tolist():
        if exclude_wells is None:
            plt.plot(df.Temperature, df[well], lw=line_width)
        elif well not in exclude_wells:
            plt.plot(df.Temperature, df[well], lw=line_width)
    
    if sample is None:
        output_filename = '_'.join([plate_id, primer_simple, 'melting_curves.svg'])
    else:
        output_filename = '_'.join([plate_id, sample, primer_simple, 'melting_curves.svg'])

    plt.title(output_filename[:-4])
    
    if save_fig:
        plt.savefig( os.path.join(output_folder, output_filename) )

def get_amplification_data(plate_id, data_folder='../data/qPCR-data'):
    ''' Given a plate id:
          1. Locate the annotation csv file and the amplification results csv file
          2. Extract useful data, merge and return the data frame
    '''
    
    exported_csv_folders = glob.glob(os.path.join(data_folder, '*'+plate_id+'*'+os.path.sep))
    assert len(exported_csv_folders) == 1
    exported_csv_folder = exported_csv_folders[0]
    
    data_files = glob.glob(os.path.join(exported_csv_folder, '*Quantification Amplification Results_SYBR.csv'))
    assert len(data_files) == 1
    data_file = data_files[0]
    
    df = pd.read_csv(data_file)
    
    # drop the first column (empty)
    df = df.iloc[:, 1:]
    
    # wells = []
    # for i in string.ascii_uppercase[:8]:
    #     for j in range(1,13):
    #         wells.append(i+'{:02d}'.format(j))
    
    # rename columns to keep the well names consistent
    # df.columns = ['Temperature'] + wells
    col_names = df.columns.tolist()
    df.columns = [i[0]+'0'+i[1] if len(i)==2 else i for i in col_names]
    
    return df

def plot_amplification_curves(plate_id,
                              primer=None,
                              log=True,
                              ymin=5,
                              ymax=3500,
                              fig_width=2.8,
                              fig_height=1.2,
                              line_width=0.8,
                              exclude_wells=None,
                              sample=None,
                              save_fig=True,
                              output_folder = '../jupyter_figures',
                              data_folder='../data/qPCR-data'):
    '''Plot amplification curves of the specificied plate_id and primer'''
    
    df_annotation = get_annotation_data(plate_id, data_folder)
    
    # select the wells based on the query of primer and sample
    if primer is None:
        df_selected = df_annotation
        primers = df_annotation.Primer.unique()
        # primers_simple = [i.split(' ')[0] for i in primers]
        primers_simple = [i.replace(' ', '') for i in primers]
        primer_simple = '_'.join(primers_simple)
    elif type(primer) is str:
        df_selected = df_annotation[df_annotation.Primer==primer]
        primer_simple = primer.replace(' ', '')
    elif type(primer) is list:
        df_selected = df_annotation[df_annotation.Primer.isin(primer)]
        primers_simple = [i.replace(' ', '') for i in primer]
        primer_simple = '_'.join(primers_simple)
        
    if sample is not None:
        if type(sample) is str:
            df_selected = df_selected[df_selected.Sample==sample]
        elif type(sample) is list:
            df_selected = df_selected[df_selected.Sample.isin(sample)]
    
    if len(df_selected) == 0:
        return
    
    fig = plt.figure(figsize=(fig_width,fig_height), dpi=300)
    ax = fig.add_axes([0.1, 0.1, 0.8, 0.8])

    df = get_amplification_data(plate_id, data_folder)
    for well in df_selected.Well.tolist():
        if exclude_wells is None:
            plt.plot(df.Cycle, df[well], lw=line_width)
        elif well not in exclude_wells:
            plt.plot(df.Cycle, df[well], lw=line_width)
            
    if log:
        plt.yscale('log')
        plt.ylim(ymin, ymax)
        
    if sample is None:
        output_filename = '_'.join([plate_id, primer_simple, 'amplification_curves.svg'])
    else:
        output_filename = '_'.join([plate_id, sample, primer_simple, 'amplification_curves.svg'])
    
    plt.title(output_filename[:-4])
    
    if save_fig:
        plt.savefig( os.path.join(output_folder, output_filename) )
        
def remove_outliers(df, rel_std_threshold = 0.25):
    ''''''
    if 'group' not in df.columns:
        df['group'] = [df.Sample[i] + '___' + df.Primer[i] for i in range(len(df))]
    if 'well_id' not in df.columns:
        df['well_id'] = [df.plate_id[i] + '-' + df.Well[i] for i in range(len(df))]
    if 'relExp_25' not in df.columns:
        df['relExp_25'] = [2**(25-df.Cq[i]) for i in range(len(df))]
    
    df_grouped = df.groupby('group').describe()['relExp_25'].reset_index()[['group', 'count', 'mean', 'std']]
    df_grouped['rel_std'] = df_grouped['std'] / df_grouped['mean']
    
    # make empty lists
    groups_to_remove, wells_to_remove = [], []
    
    # Remove groups with only 1 replicate
    if df_grouped['count'].min()<2:
        groups_to_remove = groups_to_remove + df_grouped[df_grouped['count']<2]['group'].unique()
    
    # For groups with 3 or more wells of data, when the relative std is larger than threshold:    
    #     - Remove a single outlier well from the group, if that can lower relative std below threshold
    #     - Otherwise, remove the entire group
    for group in df_grouped[df_grouped['rel_std'] > rel_std_threshold]['group'].unique():
        df_temp = df[df['group']==group]
        if len(df_temp) < 3:
            groups_to_remove.append(group)
        else:
            relExps = df_temp['relExp_25'].tolist()
            well_ids = df_temp['well_id'].tolist()
            relStds = []
            for i in range(len(relExps)):
                relExps_copy = relExps.copy()
                del relExps_copy[i]
                relStds.append(np.std(relExps_copy) / np.mean(relExps_copy))
            if np.min(relStds) <= rel_std_threshold:
                wells_to_remove.append(well_ids[np.argmin(relStds)])
            else:
                groups_to_remove.append(group)
    
    df_filtered = df[~df['well_id'].isin(wells_to_remove)]
    df_filtered = df_filtered[~df_filtered['group'].isin(groups_to_remove)]
    df_filtered.reset_index(drop=True, inplace=True)
    
    return df_filtered
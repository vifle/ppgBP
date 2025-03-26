import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.patches as patch
import numpy as np
plt.style.use('ggplot')

def plotblandaltman(x,y,name,title = None,sd_limit = 1.96):
    plt.figure(figsize=(30,10))
    if title is not None:
        plt.suptitle(title, fontsize="20")
    if len(x) != len(y):
        raise ValueError('x does not have the same length as y')
    else:
        a = np.asarray(x)

        b = np.asarray(x)+np.asarray(y)
        mean_diff = np.mean(b)
        std_diff = np.std(b, axis=0)
        limit_of_agreement = sd_limit * std_diff
        lower = mean_diff - limit_of_agreement
        upper = mean_diff + limit_of_agreement
            
        difference = upper - lower
        lowerplot = lower - (difference * 0.5)
        upperplot = upper + (difference * 0.5)
        plt.axhline(y=mean_diff, linestyle = "--", color = "red", label="mean diff")
        
        plt.axhline(y=lower, linestyle = "--", color = "grey", label="-1.96 SD")
        plt.axhline(y=upper, linestyle = "--", color = "grey", label="1.96 SD")
        
        plt.text(a.max()*0.85, upper * 1.1, " 1.96 SD", color = "grey", fontsize = "14")
        plt.text(a.max()*0.85, lower * 0.9, "-1.96 SD", color = "grey", fontsize = "14")
        plt.text(a.max()*0.85, mean_diff * 0.85, "Mean", color = "red", fontsize = "14")
        plt.ylim(lowerplot, upperplot)
        plt.scatter(x=a,y=b)
        plt.grid(visible=False)
        plt.savefig(name, bbox_inches = 'tight', pad_inches = 0)
        plt.close()
            
    # corre
            
    #         def bland_altman_plot(data1, data2, *args, **kwargs):
    # data1     = np.asarray(data1)
    # data2     = np.asarray(data2)
    # mean      = np.mean([data1, data2], axis=0)
    # diff      = data1 - data2                   # Difference between data1 and data2
    # md        = np.mean(diff)                   # Mean of the difference
    # sd        = np.std(diff, axis=0)            # Standard deviation of the difference

    # plt.scatter(mean, diff, *args, **kwargs)
    # plt.axhline(md,           color='gray', linestyle='--')
    # plt.axhline(md + 1.96*sd, color='gray', linestyle='--')
    # plt.axhline(md - 1.96*sd, color='gray', linestyle='--')
    
def plotComparison(prediction,groundTruth,name,subjects=[],plotPatches=False,yLimits=[None,None]):
    plt.figure()
    plt.plot(prediction,label='prediction',linewidth=0.5)
    plt.plot(groundTruth,label='ground truth',linewidth=0.5)
    plt.xlabel('sample')
    plt.ylabel('blood pressure / mmHg')
    #plt.legend()
    if plotPatches:
        patchStart = 0
        for idxSubject,_ in enumerate(subjects):
            if(idxSubject%2 == 0):
                colorPatch = 'g'
            else:
                colorPatch = 'w'
            # find number of samples of subject
            # NOTE: camera estimates are at end of array, but have same identifier
            
            #idx = find(evaluationResults.testTable.ID==testSubs(currentSubject));
            
            #patchEnd = patchStart + length(idx)-1;
            #plt.axvspan(patchStart, patchEnd, facecolor=colorPatch, alpha=0.25)
            #patchStart = patchEnd+1  
    if yLimits[0] is not None:
        plt.ylim((yLimits[0], yLimits[1])) 
    plt.grid(visible=False)
    plt.savefig(name, bbox_inches = 'tight', pad_inches = 0)
    plt.close()
    
def plotComparisonSub(prediction,groundTruth,name,subjects=[],yLimits=[None,None]):
    fig, axs = plt.subplots(len(prediction))
    for i in range(len(prediction)):
        axs[i].plot(prediction[i],label='prediction',linewidth=0.5)
        axs[i].plot(groundTruth[i],label='ground truth',linewidth=0.5)
        if i==0 or i==1:
            newLabels = axs[i].get_xticklabels()
            newLabels[0].set_text('$\\mathdefault{-2000}$') #6,7,8,9
            newLabels[1].set_text('$\\mathdefault{0}$') #6,7,8,9
            newLabels[2].set_text('$\\mathdefault{2000}$') #6,7,8,9
            newLabels[3].set_text('$\\mathdefault{4000}$') #6,7,8,9
            newLabels[4].set_text('$\\mathdefault{6000}$') #6,7,8,9
            newLabels[5].set_text('$\\mathdefault{8000}$') #6,7,8,9
            newLabels[6].set_text('$\\mathdefault{10{,}000}$') #6,7,8,9
            newLabels[7].set_text('$\\mathdefault{12{,}000}$') #6,7,8,9
            newLabels[8].set_text('$\\mathdefault{14{,}000}$') #6,7,8,9
            newLabels[9].set_text('$\\mathdefault{16{,}000}$') #6,7,8,9
            axs[i].set_xticklabels(newLabels)
        
        # axs[i].xaxis.set_major_formatter(mpl.ticker.StrMethodFormatter('{x:,.0f}'))
        #if yLimits[0] is not None:
        #    axs[i].ylim((yLimits[0], yLimits[1])) 
        axs[i].grid(visible=False)
    if yLimits[0] is not None:
        plt.setp(axs, ylim=yLimits)
    #plt.xlabel('sample')
    #plt.ylabel('blood pressure / mmHg')
    fig.supxlabel('sample')
    fig.supylabel('blood pressure / mmHg')
    plt.savefig(name, bbox_inches = 'tight', pad_inches = 0)
    plt.close()
import matplotlib.pyplot as plt
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
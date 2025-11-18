package com.rakuten.room.reels.flutter

import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import io.flutter.embedding.android.FlutterFragment
import com.rakuten.room.reels.CollectData
import com.rakuten.room.reels.ReelsModule

class FlutterReelsFragment : Fragment() {

    private var flutterFragment: FlutterFragment? = null

    companion object {
        private const val TAG = "FlutterReelsFragment"
        private const val ARG_ROUTE = "initial_route"
        private const val ARG_COLLECT_DATA = "collect_data"
        private const val ARG_GENERATION = "generation"

        fun newInstance(
            initialRoute: String = "/",
            collectData: CollectData? = null,
            generation: Int = 0
        ): FlutterReelsFragment {
            val fragment = FlutterReelsFragment()
            val args = Bundle()
            args.putString(ARG_ROUTE, initialRoute)
            collectData?.let { args.putParcelable(ARG_COLLECT_DATA, it) }
            args.putInt(ARG_GENERATION, generation)
            fragment.arguments = args
            return fragment
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val initialRoute = arguments?.getString(ARG_ROUTE) ?: "/"
        val collectData = arguments?.getParcelable<CollectData>(ARG_COLLECT_DATA)
        val generation = arguments?.getInt(ARG_GENERATION, 0) ?: 0

        if (collectData != null) {
            Log.d(TAG, "Received collectData: id=${collectData.id}, generation=$generation")
        } else {
            Log.d(TAG, "No collectData provided, generation=$generation")
        }

        // Initialize Flutter engine if not already done
        FlutterEngineManager.getInstance().initializeFlutterEngine(requireContext())
        
        val engineManager = FlutterEngineManager.getInstance()
        flutterFragment = FlutterFragment.withCachedEngine(engineManager.getFlutterEngineId())
            .build()
        
        childFragmentManager
            .beginTransaction()
            .add(android.R.id.content, flutterFragment!!)
            .commit()
        
        return flutterFragment?.view
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "FlutterReelsFragment resumed")

        // Resume Flutter resources for this generation
        val generation = arguments?.getInt(ARG_GENERATION, 0) ?: 0
        if (generation > 0) {
            ReelsModule.resumeFlutter(generation)
        }
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "FlutterReelsFragment paused")

        // Pause Flutter resources
        ReelsModule.pauseFlutter()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        flutterFragment?.let {
            childFragmentManager
                .beginTransaction()
                .remove(it)
                .commit()
        }
        flutterFragment = null
    }
}